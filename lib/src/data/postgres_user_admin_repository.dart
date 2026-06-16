import 'package:postgres/postgres.dart';

import '../domain/user_admin_models.dart';
import 'operix_database.dart';
import 'password_hasher.dart';
import 'user_admin_repository.dart';

class PostgresUserAdminRepository implements UserAdminRepository {
  PostgresUserAdminRepository(this.database);

  final OperixDatabase database;

  @override
  Future<List<ManagedUser>> list({
    String search = '',
    bool includeInactive = true,
  }) async {
    final conn = await database.connection();
    final query = search.trim();
    final result = await conn.execute(
      Sql.named('''
        SELECT id, username, full_name, role, is_active, last_login_at,
               created_at
        FROM users
        WHERE (@include_inactive OR is_active = TRUE)
          AND (
            @q = ''
            OR full_name ILIKE '%' || @q || '%'
            OR username ILIKE '%' || @q || '%'
            OR role ILIKE '%' || @q || '%'
          )
        ORDER BY full_name ASC
      '''),
      parameters: {'include_inactive': includeInactive, 'q': query},
    );
    return result.map((row) => _user(row.toColumnMap())).toList();
  }

  @override
  Future<ManagedUser> create(UserDraft draft) async {
    final password = draft.password;
    if (password == null || password.isEmpty) {
      throw const UserAdminException('A password is required for a new user.');
    }
    final conn = await database.connection();
    await _ensureUsernameFree(conn, draft.username, null);
    final result = await conn.execute(
      Sql.named('''
        INSERT INTO users (username, full_name, password_hash, role, is_active)
        VALUES (@username, @full_name, @password_hash, @role, @is_active)
        RETURNING id, username, full_name, role, is_active, last_login_at,
                  created_at
      '''),
      parameters: {
        'username': draft.username.trim(),
        'full_name': draft.fullName.trim(),
        'password_hash': PasswordHasher.hash(password),
        'role': draft.role,
        'is_active': draft.isActive,
      },
    );
    return _user(result.first.toColumnMap());
  }

  @override
  Future<ManagedUser> update(int id, UserDraft draft) async {
    final conn = await database.connection();
    await _ensureUsernameFree(conn, draft.username, id);

    // Guard against demoting/deactivating the last active admin.
    final losingAdmin = draft.role.toLowerCase() != 'admin' || !draft.isActive;
    if (losingAdmin && await _isLastActiveAdmin(conn, id)) {
      throw const LastAdminException();
    }

    final setPassword = draft.password != null && draft.password!.isNotEmpty;
    final result = await conn.execute(
      Sql.named('''
        UPDATE users SET
          username = @username,
          full_name = @full_name,
          role = @role,
          is_active = @is_active
          ${setPassword ? ', password_hash = @password_hash' : ''}
        WHERE id = @id
        RETURNING id, username, full_name, role, is_active, last_login_at,
                  created_at
      '''),
      parameters: {
        'id': id,
        'username': draft.username.trim(),
        'full_name': draft.fullName.trim(),
        'role': draft.role,
        'is_active': draft.isActive,
        if (setPassword) 'password_hash': PasswordHasher.hash(draft.password!),
      },
    );
    if (result.isEmpty) {
      throw const UserAdminException('User not found.');
    }
    return _user(result.first.toColumnMap());
  }

  @override
  Future<void> delete(int id) async {
    final conn = await database.connection();
    if (await _isLastActiveAdmin(conn, id)) {
      throw const LastAdminException();
    }
    await conn.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<void> _ensureUsernameFree(
    Connection conn,
    String username,
    int? excludeId,
  ) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT 1 FROM users
        WHERE LOWER(username) = LOWER(@username)
          AND (@exclude_id::bigint IS NULL OR id <> @exclude_id)
        LIMIT 1
      '''),
      parameters: {'username': username.trim(), 'exclude_id': excludeId},
    );
    if (result.isNotEmpty) {
      throw DuplicateUsernameException(username.trim());
    }
  }

  /// True when [id] is currently an active admin and the only one.
  Future<bool> _isLastActiveAdmin(Connection conn, int id) async {
    final result = await conn.execute(
      Sql.named('''
        SELECT
          (SELECT COUNT(*) FROM users
             WHERE LOWER(role) = 'admin' AND is_active = TRUE) AS admin_count,
          (SELECT (LOWER(role) = 'admin' AND is_active = TRUE) FROM users
             WHERE id = @id) AS is_active_admin
      '''),
      parameters: {'id': id},
    );
    final map = result.first.toColumnMap();
    final count = _asInt(map['admin_count']);
    final isActiveAdmin = map['is_active_admin'] as bool? ?? false;
    return isActiveAdmin && count <= 1;
  }

  ManagedUser _user(Map<String, dynamic> map) {
    return ManagedUser(
      id: _asInt(map['id']),
      username: map['username']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      role: map['role']?.toString() ?? 'cashier',
      isActive: map['is_active'] as bool? ?? true,
      lastLoginAt: _asDateOrNull(map['last_login_at']),
      createdAt: _asDateOrNull(map['created_at']),
    );
  }

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  DateTime? _asDateOrNull(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
