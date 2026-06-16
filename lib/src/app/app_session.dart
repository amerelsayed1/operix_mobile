import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/role_repository.dart';
import '../domain/operix_models.dart';
import '../domain/pos_models.dart';

/// Holds the signed-in user and the active cashier shift for the session.
/// Exposed via `provider` so any screen can read or react to changes.
///
/// The signed-in user is persisted to [SharedPreferences] so the session
/// survives an app restart — without this the user would have to log in every
/// time the desktop app is reopened. On startup, main() looks up the stored
/// user id and passes the restored [AppUser] in as [initialUser].
///
/// The session also caches the granted permission keys for the user's role and
/// is the single source of truth for access control ([can], [isAdmin]). The UI
/// gates navigation and screens off these so a low-privilege user cannot reach
/// admin areas (Users, Roles, Settings).
class AppSession extends ChangeNotifier {
  AppSession({
    SharedPreferences? prefs,
    RoleRepository? roleRepository,
    AppUser? initialUser,
    Set<String>? initialPermissions,
  }) : _prefs = prefs,
       _roleRepository = roleRepository,
       _user = initialUser,
       _permissions = {...?initialPermissions} {
    _isAdmin = _computeIsAdmin(initialUser, _permissions);
  }

  /// SharedPreferences key holding the id of the last signed-in user.
  static const String userIdKey = 'session_user_id';

  /// Role name that always has full access regardless of the granted set.
  static const String adminRoleName = 'admin';

  final SharedPreferences? _prefs;
  final RoleRepository? _roleRepository;

  AppUser? _user;
  PosShift? _shift;
  Set<String> _permissions;
  bool _isAdmin = false;

  AppUser? get user => _user;
  PosShift? get shift => _shift;

  bool get isAuthenticated => _user != null;
  bool get hasOpenShift => _shift != null && _shift!.isOpen;

  /// Whether the current user has the tenant administrator role (full access).
  bool get isAdmin => _isAdmin;

  /// The granted permission keys for the current user's role.
  Set<String> get permissions => Set.unmodifiable(_permissions);

  /// Whether the current user may perform the action identified by [key]
  /// (e.g. `pos.enter`, `settings.view`). Admins can do everything.
  bool can(String key) => _isAdmin || _permissions.contains(key);

  /// Whether the current user may open [module]. Modules with no associated
  /// permission key are considered always-available.
  bool canAccessModule(OperixModule module) {
    final key = modulePermissionKey(module);
    return key == null || can(key);
  }

  Future<void> signIn(AppUser user) async {
    _user = user;
    _shift = null;
    _prefs?.setInt(userIdKey, user.id);
    await _loadPermissions(user);
    _isAdmin = _computeIsAdmin(user, _permissions);
    notifyListeners();
  }

  void signOut() {
    _user = null;
    _shift = null;
    _permissions = <String>{};
    _isAdmin = false;
    _prefs?.remove(userIdKey);
    notifyListeners();
  }

  void setShift(PosShift? shift) {
    _shift = shift;
    notifyListeners();
  }

  Future<void> _loadPermissions(AppUser user) async {
    final repo = _roleRepository;
    if (repo == null) {
      _permissions = <String>{};
      return;
    }
    try {
      _permissions = await repo.permissionsFor(user.role);
    } catch (_) {
      // Fail closed: if permissions can't be loaded, grant nothing (admins are
      // still recognised by role name below).
      _permissions = <String>{};
    }
  }

  static bool _computeIsAdmin(AppUser? user, Set<String> permissions) {
    if (user == null) return false;
    return user.role.trim().toLowerCase() == adminRoleName;
  }
}

/// Maps a navigation [module] to the permission key required to open it, or
/// `null` when the module has no dedicated permission (always available).
/// Centralised here so the shell and the session agree on the gating.
String? modulePermissionKey(OperixModule module) {
  switch (module) {
    case OperixModule.dashboard:
      return 'dashboard.view';
    case OperixModule.pointOfSale:
      return 'pos.enter';
    case OperixModule.sales:
      return 'salesInvoices.view';
    case OperixModule.clients:
      return 'crm.view';
    case OperixModule.users:
      return 'employees.view';
    case OperixModule.settings:
      return 'settings.view';
    case OperixModule.purchases:
    case OperixModule.inventory:
    case OperixModule.suppliers:
    case OperixModule.reports:
    case OperixModule.accounting:
      return null;
  }
}
