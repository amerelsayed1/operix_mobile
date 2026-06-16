import '../domain/user_admin_models.dart';
import 'user_admin_repository.dart';

/// In-memory user store for demo mode. Seeds nothing; the first-run setup in
/// demo mode creates the admin via the demo auth repository, so this list can be
/// empty until users are added here.
class DemoUserAdminRepository implements UserAdminRepository {
  final List<ManagedUser> _users = [];
  int _seq = 1;

  @override
  Future<List<ManagedUser>> list({
    String search = '',
    bool includeInactive = true,
  }) async {
    final q = search.trim().toLowerCase();
    final filtered =
        _users.where((u) {
          if (!includeInactive && !u.isActive) return false;
          if (q.isEmpty) return true;
          return u.fullName.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q);
        }).toList()..sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
    return filtered;
  }

  @override
  Future<ManagedUser> create(UserDraft draft) async {
    if (draft.password == null || draft.password!.isEmpty) {
      throw const UserAdminException('A password is required for a new user.');
    }
    if (_users.any(
      (u) => u.username.toLowerCase() == draft.username.trim().toLowerCase(),
    )) {
      throw DuplicateUsernameException(draft.username.trim());
    }
    final user = _fromDraft(_seq++, draft);
    _users.add(user);
    return user;
  }

  @override
  Future<ManagedUser> update(int id, UserDraft draft) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index < 0) throw const UserAdminException('User not found.');
    if (_users.any(
      (u) =>
          u.id != id &&
          u.username.toLowerCase() == draft.username.trim().toLowerCase(),
    )) {
      throw DuplicateUsernameException(draft.username.trim());
    }
    if ((draft.role.toLowerCase() != 'admin' || !draft.isActive) &&
        _isLastActiveAdmin(id)) {
      throw const LastAdminException();
    }
    final user = _fromDraft(id, draft);
    _users[index] = user;
    return user;
  }

  @override
  Future<void> delete(int id) async {
    if (_isLastActiveAdmin(id)) throw const LastAdminException();
    _users.removeWhere((u) => u.id == id);
  }

  bool _isLastActiveAdmin(int id) {
    final admins = _users.where((u) => u.isAdmin && u.isActive).toList();
    return admins.length <= 1 && admins.any((u) => u.id == id);
  }

  ManagedUser _fromDraft(int id, UserDraft d) {
    return ManagedUser(
      id: id,
      username: d.username.trim(),
      fullName: d.fullName.trim(),
      role: d.role,
      isActive: d.isActive,
    );
  }
}
