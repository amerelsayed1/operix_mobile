import '../domain/role_models.dart';
import 'role_repository.dart';

/// In-memory role store for demo mode. Seeds the same two roles the web app
/// ships with: a system Administrator (all permissions) and a Cashier with POS
/// and shift access.
class DemoRoleRepository implements RoleRepository {
  DemoRoleRepository() {
    _roles
      ..add(
        Role(
          id: _seq++,
          name: 'Admin',
          description: 'Tenant Administrator with full access',
          isSystem: true,
          memberCount: 1,
          permissions: allPermissionKeys.toSet(),
        ),
      )
      ..add(
        Role(
          id: _seq++,
          name: 'كاشير',
          description: '',
          isSystem: false,
          memberCount: 0,
          permissions: {
            for (final group in kPermissionCatalog)
              if (group.key == 'pos')
                for (final module in group.modules) ...module.permissionKeys,
          },
        ),
      );
  }

  final List<Role> _roles = [];
  int _seq = 1;

  @override
  Future<List<Role>> list() async => List.unmodifiable(_roles);

  @override
  Future<Role> create(RoleDraft draft) async {
    _ensureNameFree(draft.name, null);
    final role = Role(
      id: _seq++,
      name: draft.name.trim(),
      description: draft.description.trim(),
      isSystem: false,
      memberCount: 0,
      permissions: {...draft.permissions},
    );
    _roles.add(role);
    return role;
  }

  @override
  Future<Role> update(int id, RoleDraft draft) async {
    final index = _roles.indexWhere((r) => r.id == id);
    if (index < 0) throw const RoleException('Role not found.');
    _ensureNameFree(draft.name, id);
    final existing = _roles[index];
    final updated = Role(
      id: id,
      name: draft.name.trim(),
      description: draft.description.trim(),
      isSystem: existing.isSystem,
      memberCount: existing.memberCount,
      permissions: {...draft.permissions},
    );
    _roles[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(int id) async {
    final role = _roles.firstWhere(
      (r) => r.id == id,
      orElse: () => throw const RoleException('Role not found.'),
    );
    if (role.isSystem) throw const SystemRoleException();
    _roles.removeWhere((r) => r.id == id);
  }

  @override
  Future<Set<String>> permissionsFor(String roleName) async {
    final q = roleName.trim().toLowerCase();
    for (final role in _roles) {
      if (role.name.toLowerCase() == q) return {...role.permissions};
    }
    return <String>{};
  }

  void _ensureNameFree(String name, int? excludeId) {
    final q = name.trim().toLowerCase();
    if (_roles.any((r) => r.id != excludeId && r.name.toLowerCase() == q)) {
      throw DuplicateRoleException(name.trim());
    }
  }
}
