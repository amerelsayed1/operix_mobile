import '../domain/pos_models.dart';

/// Outcome of a sign-in attempt.
enum AuthFailure {
  invalidCredentials,
  inactiveUser,
  connection,
  alreadyInitialized,
}

class AuthException implements Exception {
  const AuthException(this.failure, this.message);

  final AuthFailure failure;
  final String message;

  @override
  String toString() => 'AuthException($failure): $message';
}

/// Role assigned to the very first account created from the setup screen.
const String kAdminRole = 'admin';

abstract interface class AuthRepository {
  /// Whether any user account exists yet. Drives first-run setup vs. login.
  Future<bool> hasUsers();

  /// Creates the first administrator account. Throws [AuthException] with
  /// [AuthFailure.alreadyInitialized] if users already exist.
  Future<AppUser> createFirstAdmin({
    required String username,
    required String fullName,
    required String password,
  });

  /// Returns the authenticated user, or throws [AuthException] on failure.
  Future<AppUser> login(String username, String password);

  /// Looks up an active user by id, used to restore a persisted session on
  /// startup. Returns null if the user no longer exists or is inactive.
  Future<AppUser?> findUser(int id);
}
