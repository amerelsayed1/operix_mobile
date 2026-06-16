import '../domain/role_models.dart';

class RoleException implements Exception {
  const RoleException(this.message);
  final String message;
  @override
  String toString() => 'RoleException: $message';
}

/// Raised when a role name collides with an existing role.
class DuplicateRoleException extends RoleException {
  const DuplicateRoleException(String name)
    : super('A role named "$name" already exists.');
}

/// Raised when a system role (e.g. the administrator) is deleted.
class SystemRoleException extends RoleException {
  const SystemRoleException() : super('System roles cannot be deleted.');
}

/// Management of tenant roles and their granted permissions.
abstract interface class RoleRepository {
  Future<List<Role>> list();

  Future<Role> create(RoleDraft draft);

  Future<Role> update(int id, RoleDraft draft);

  /// Deletes a role. Throws [SystemRoleException] for system roles.
  Future<void> delete(int id);

  /// The granted permission keys for the role named [roleName] (case-insensitive).
  /// Used to enforce access control for the signed-in user. An unknown role
  /// resolves to no permissions (fail closed).
  Future<Set<String>> permissionsFor(String roleName);
}
