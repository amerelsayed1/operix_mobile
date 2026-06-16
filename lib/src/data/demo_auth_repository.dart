import '../domain/pos_models.dart';
import 'auth_repository.dart';

class _DemoUser {
  _DemoUser(this.user, this.password);
  final AppUser user;
  final String password;
}

/// In-memory auth used when PostgreSQL is not configured. Starts empty, so the
/// app shows the first-run setup screen just like a fresh database.
class DemoAuthRepository implements AuthRepository {
  final List<_DemoUser> _users = [];

  @override
  Future<bool> hasUsers() async => _users.isNotEmpty;

  @override
  Future<AppUser> createFirstAdmin({
    required String username,
    required String fullName,
    required String password,
  }) async {
    if (_users.isNotEmpty) {
      throw const AuthException(
        AuthFailure.alreadyInitialized,
        'An account already exists. Please sign in instead.',
      );
    }
    final user = AppUser(
      id: 1,
      username: username.trim(),
      fullName: fullName.trim(),
      role: kAdminRole,
    );
    _users.add(_DemoUser(user, password));
    return user;
  }

  @override
  Future<AppUser> login(String username, String password) async {
    final name = username.trim().toLowerCase();
    for (final entry in _users) {
      if (entry.user.username.toLowerCase() == name) {
        if (entry.password != password) {
          throw const AuthException(
            AuthFailure.invalidCredentials,
            'Incorrect username or password.',
          );
        }
        return entry.user;
      }
    }
    throw const AuthException(
      AuthFailure.invalidCredentials,
      'Incorrect username or password.',
    );
  }

  @override
  Future<AppUser?> findUser(int id) async {
    for (final entry in _users) {
      if (entry.user.id == id) return entry.user;
    }
    return null;
  }
}
