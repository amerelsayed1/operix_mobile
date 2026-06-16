import '../domain/user_admin_models.dart';

class UserAdminException implements Exception {
  const UserAdminException(this.message);
  final String message;
  @override
  String toString() => 'UserAdminException: $message';
}

/// Raised when a username collides with an existing user.
class DuplicateUsernameException extends UserAdminException {
  const DuplicateUsernameException(String username)
    : super('A user with username "$username" already exists.');
}

/// Raised when an operation would leave the system with no active administrator
/// (which would lock everyone out).
class LastAdminException extends UserAdminException {
  const LastAdminException()
    : super('At least one active administrator must remain.');
}

/// Administration of local user accounts (separate from [AuthRepository], which
/// only handles sign-in / first-run setup).
abstract interface class UserAdminRepository {
  Future<List<ManagedUser>> list({
    String search = '',
    bool includeInactive = true,
  });

  /// Creates a user. [UserDraft.password] is required.
  Future<ManagedUser> create(UserDraft draft);

  /// Updates a user. A null/empty [UserDraft.password] keeps the current one.
  /// Throws [LastAdminException] if this would remove the last active admin.
  Future<ManagedUser> update(int id, UserDraft draft);

  /// Deletes a user. Throws [LastAdminException] for the last active admin.
  Future<void> delete(int id);
}
