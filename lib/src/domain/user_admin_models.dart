// User-administration domain models for the Users module: the list and the
// create/edit form. Mirrors the local `users` table (002 schema):
// id, username, full_name, password_hash, role, is_active, last_login_at,
// created_at. Passwords are never held here — only set through the draft and
// hashed by the repository.

/// Roles a local user can hold. `admin` has full access; the others are
/// operational. The very first account is always created as `admin`.
const List<String> kUserRoles = ['admin', 'manager', 'cashier'];

/// A user account as shown in the administration list.
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
  });

  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  bool get isAdmin => role.toLowerCase() == 'admin';
}

/// Input for creating or updating a user. [password] is required on create and
/// optional on update (null/empty = keep the existing password).
class UserDraft {
  const UserDraft({
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.password,
  });

  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final String? password;
}
