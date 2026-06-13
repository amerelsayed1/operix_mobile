import 'package:postgres/postgres.dart';

import '../domain/pos_models.dart';
import 'auth_repository.dart';
import 'operix_database.dart';
import 'password_hasher.dart';

class PostgresAuthRepository implements AuthRepository {
  PostgresAuthRepository(this.database);

  final OperixDatabase database;

  @override
  Future<bool> hasUsers() async {
    final conn = await database.connection();
    final result = await conn.execute(
      'SELECT EXISTS(SELECT 1 FROM users) AS present',
    );
    return result.first.toColumnMap()['present'] as bool? ?? false;
  }

  @override
  Future<AppUser> createFirstAdmin({
    required String username,
    required String fullName,
    required String password,
  }) async {
    final Connection conn;
    try {
      conn = await database.connection();
    } catch (error) {
      throw AuthException(
        AuthFailure.connection,
        'Could not reach the database: $error',
      );
    }

    return conn.runTx((session) async {
      final existing = await session.execute(
        'SELECT EXISTS(SELECT 1 FROM users) AS present',
      );
      if (existing.first.toColumnMap()['present'] as bool? ?? false) {
        throw const AuthException(
          AuthFailure.alreadyInitialized,
          'An account already exists. Please sign in instead.',
        );
      }

      final result = await session.execute(
        Sql.named('''
          INSERT INTO users (username, full_name, password_hash, role)
          VALUES (@username, @full_name, @password_hash, @role)
          RETURNING id
        '''),
        parameters: {
          'username': username.trim(),
          'full_name': fullName.trim(),
          'password_hash': PasswordHasher.hash(password),
          'role': kAdminRole,
        },
      );

      return AppUser(
        id: result.first.toColumnMap()['id'] as int,
        username: username.trim(),
        fullName: fullName.trim(),
        role: kAdminRole,
      );
    });
  }

  @override
  Future<AppUser> login(String username, String password) async {
    final Connection conn;
    final Result result;
    try {
      conn = await database.connection();
      result = await conn.execute(
        Sql.named('''
          SELECT id, username, full_name, role, password_hash, is_active
          FROM users
          WHERE LOWER(username) = LOWER(@username)
          LIMIT 1
        '''),
        parameters: {'username': username.trim()},
      );
    } catch (error) {
      throw AuthException(
        AuthFailure.connection,
        'Could not reach the database: $error',
      );
    }

    if (result.isEmpty) {
      throw const AuthException(
        AuthFailure.invalidCredentials,
        'Incorrect username or password.',
      );
    }

    final row = result.first.toColumnMap();
    final hash = row['password_hash'] as String? ?? '';
    if (!PasswordHasher.verify(password, hash)) {
      throw const AuthException(
        AuthFailure.invalidCredentials,
        'Incorrect username or password.',
      );
    }

    final isActive = row['is_active'] as bool? ?? true;
    if (!isActive) {
      throw const AuthException(
        AuthFailure.inactiveUser,
        'This user account is disabled.',
      );
    }

    final id = row['id'] as int;
    await conn.execute(
      Sql.named('UPDATE users SET last_login_at = NOW() WHERE id = @id'),
      parameters: {'id': id},
    );

    return AppUser(
      id: id,
      username: row['username'] as String? ?? username,
      fullName: row['full_name'] as String? ?? username,
      role: row['role'] as String? ?? kAdminRole,
    );
  }
}
