import 'package:postgres/postgres.dart';

import '../domain/role_models.dart';
import 'operix_database.dart';
import 'role_repository.dart';

class PostgresRoleRepository implements RoleRepository {
  PostgresRoleRepository(this.database);

  final OperixDatabase database;

  bool _ensured = false;

  @override
  Future<List<Role>> list() async {
    final conn = await database.connection();
    await _ensureSchema(conn);
    final rows = await conn.execute('''
      SELECT
        r.id,
        r.name,
        r.description,
        r.is_system,
        (SELECT COUNT(*) FROM users u
           WHERE LOWER(u.role) = LOWER(r.name)) AS member_count,
        COALESCE(
          ARRAY(
            SELECT rp.permission_key FROM role_permissions rp
             WHERE rp.role_id = r.id
          ),
          ARRAY[]::text[]
        ) AS permissions
      FROM roles r
      ORDER BY r.is_system DESC, r.name ASC
    ''');
    return rows.map((row) => _role(row.toColumnMap())).toList();
  }

  @override
  Future<Role> create(RoleDraft draft) async {
    final conn = await database.connection();
    await _ensureSchema(conn);
    await _ensureNameFree(conn, draft.name, null);
    return conn.runTx((tx) async {
      final result = await tx.execute(
        Sql.named('''
          INSERT INTO roles (name, description, is_system)
          VALUES (@name, @description, FALSE)
          RETURNING id, name, description, is_system
        '''),
        parameters: {
          'name': draft.name.trim(),
          'description': draft.description.trim(),
        },
      );
      final id = _asInt(result.first.toColumnMap()['id']);
      await _replacePermissions(tx, id, draft.permissions);
      return Role(
        id: id,
        name: draft.name.trim(),
        description: draft.description.trim(),
        isSystem: false,
        memberCount: 0,
        permissions: {...draft.permissions},
      );
    });
  }

  @override
  Future<Role> update(int id, RoleDraft draft) async {
    final conn = await database.connection();
    await _ensureSchema(conn);
    await _ensureNameFree(conn, draft.name, id);
    return conn.runTx((tx) async {
      final result = await tx.execute(
        Sql.named('''
          UPDATE roles SET name = @name, description = @description
          WHERE id = @id
          RETURNING id, name, description, is_system
        '''),
        parameters: {
          'id': id,
          'name': draft.name.trim(),
          'description': draft.description.trim(),
        },
      );
      if (result.isEmpty) throw const RoleException('Role not found.');
      await _replacePermissions(tx, id, draft.permissions);
      final map = result.first.toColumnMap();
      return Role(
        id: id,
        name: draft.name.trim(),
        description: draft.description.trim(),
        isSystem: map['is_system'] as bool? ?? false,
        memberCount: await _memberCount(tx, draft.name),
        permissions: {...draft.permissions},
      );
    });
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    await _ensureSchema(conn);
    final check = await conn.execute(
      Sql.named('SELECT is_system FROM roles WHERE id = @id'),
      parameters: {'id': id},
    );
    if (check.isEmpty) throw const RoleException('Role not found.');
    if (check.first.toColumnMap()['is_system'] as bool? ?? false) {
      throw const SystemRoleException();
    }
    await conn.execute(
      Sql.named('DELETE FROM roles WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  @override
  Future<Set<String>> permissionsFor(String roleName) async {
    final conn = await database.connection();
    await _ensureSchema(conn);
    final rows = await conn.execute(
      Sql.named('''
        SELECT rp.permission_key
        FROM role_permissions rp
        JOIN roles r ON r.id = rp.role_id
        WHERE LOWER(r.name) = LOWER(@name)
      '''),
      parameters: {'name': roleName.trim()},
    );
    return {
      for (final row in rows)
        if (row.toColumnMap()['permission_key'] != null)
          row.toColumnMap()['permission_key'].toString(),
    };
  }

  Future<void> _replacePermissions(
    TxSession tx,
    int roleId,
    Set<String> permissions,
  ) async {
    await tx.execute(
      Sql.named('DELETE FROM role_permissions WHERE role_id = @id'),
      parameters: {'id': roleId},
    );
    final valid = allPermissionKeys.toSet();
    for (final key in permissions.where(valid.contains)) {
      await tx.execute(
        Sql.named('''
          INSERT INTO role_permissions (role_id, permission_key)
          VALUES (@role_id, @key)
          ON CONFLICT DO NOTHING
        '''),
        parameters: {'role_id': roleId, 'key': key},
      );
    }
  }

  Future<int> _memberCount(TxSession tx, String roleName) async {
    final result = await tx.execute(
      Sql.named('''
        SELECT COUNT(*) AS c FROM users WHERE LOWER(role) = LOWER(@name)
      '''),
      parameters: {'name': roleName.trim()},
    );
    return _asInt(result.first.toColumnMap()['c']);
  }

  Future<void> _ensureNameFree(
    Connection conn,
    String name,
    int? excludeId,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM roles
        WHERE LOWER(name) = LOWER(@name)
          AND (@exclude_id::bigint IS NULL OR id <> @exclude_id)
        LIMIT 1
      '''),
      parameters: {'name': name.trim(), 'exclude_id': excludeId},
    );
    if (result.isNotEmpty) {
      throw DuplicateRoleException(name.trim());
    }
  }

  /// Creates the roles tables on first use and seeds the system Admin role.
  /// Idempotent so the app works even if the SQL migration has not been run.
  Future<void> _ensureSchema(Connection conn) async {
    if (_ensured) return;
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS roles (
        id BIGSERIAL PRIMARY KEY,
        name VARCHAR(80) NOT NULL UNIQUE,
        description VARCHAR(255) NOT NULL DEFAULT '',
        is_system BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    ''');
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS role_permissions (
        role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
        permission_key VARCHAR(120) NOT NULL,
        PRIMARY KEY (role_id, permission_key)
      )
    ''');
    await conn.execute('''
      INSERT INTO roles (name, description, is_system)
      VALUES ('Admin', 'Tenant Administrator with full access', TRUE)
      ON CONFLICT (name) DO NOTHING
    ''');
    // Ensure the Admin role always holds the full permission set.
    final admin = await conn.execute(
      "SELECT id FROM roles WHERE name = 'Admin' LIMIT 1",
    );
    if (admin.isNotEmpty) {
      final id = _asInt(admin.first.toColumnMap()['id']);
      for (final key in allPermissionKeys) {
        await conn.execute(
          Sql.named('''
            INSERT INTO role_permissions (role_id, permission_key)
            VALUES (@id, @key)
            ON CONFLICT DO NOTHING
          '''),
          parameters: {'id': id, 'key': key},
        );
      }
    }
    _ensured = true;
  }

  Role _role(Map<String, dynamic> map) {
    final raw = map['permissions'];
    final permissions = <String>{};
    if (raw is List) {
      permissions.addAll(raw.map((e) => e.toString()));
    }
    return Role(
      id: _asInt(map['id']),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isSystem: map['is_system'] as bool? ?? false,
      memberCount: _asInt(map['member_count']),
      permissions: permissions,
    );
  }

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
