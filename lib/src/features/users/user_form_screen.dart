import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/role_repository.dart';
import '../../data/user_admin_repository.dart';
import '../../domain/role_models.dart';
import '../../domain/user_admin_models.dart';

/// Create / edit user form. Pushed as a full-screen route; pops `true` when a
/// user is saved.
class UserFormScreen extends StatefulWidget {
  const UserFormScreen({required this.repository, this.user, super.key});

  final UserAdminRepository repository;
  final ManagedUser? user;

  bool get isEditing => user != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  String _role = 'cashier';
  List<Role> _roles = const [];
  bool _rolesLoaded = false;
  bool _isActive = true;
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user != null) {
      _fullName.text = user.fullName;
      _username.text = user.username;
      _role = user.role;
      _isActive = user.isActive;
    }
    _loadRoles();
  }

  /// Loads the tenant roles defined in Settings → Roles & permissions so the
  /// dropdown reflects roles the business actually created.
  Future<void> _loadRoles() async {
    final roles = await context.read<RoleRepository>().list();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _rolesLoaded = true;
      _role = _matchRole(roles, _role, preferNonSystem: !widget.isEditing);
    });
  }

  /// Returns the catalog role name matching [desired] (case-insensitive). When
  /// there is no match, falls back to the first non-system role (so new users
  /// don't default to the administrator) and finally to the first role.
  String _matchRole(
    List<Role> roles,
    String desired, {
    bool preferNonSystem = false,
  }) {
    if (roles.isEmpty) return desired;
    for (final role in roles) {
      if (role.name.toLowerCase() == desired.toLowerCase()) return role.name;
    }
    if (preferNonSystem) {
      for (final role in roles) {
        if (!role.isSystem) return role.name;
      }
    }
    return roles.first.name;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Guard against privilege escalation: only an administrator may grant a
    // system role (e.g. Admin). This backstops the filtered dropdown below.
    if (!context.read<AppSession>().isAdmin && _isSystemRole(_role)) {
      setState(() => _error = context.l10n.cannotAssignAdminRole);
      return;
    }

    final password = _password.text.trim();
    final draft = UserDraft(
      username: _username.text,
      fullName: _fullName.text,
      role: _role,
      isActive: _isActive,
      password: password.isEmpty ? null : password,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEditing) {
        await widget.repository.update(widget.user!.id, draft);
      } else {
        await widget.repository.create(draft);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on UserAdminException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.couldNotSaveUser('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: OperixColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editUserTitle : l10n.newUser),
        backgroundColor: Colors.white,
        foregroundColor: OperixColors.ink,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: OperixColors.border)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: l10n.sectionUserDetails,
                    children: [
                      _field(
                        controller: _fullName,
                        label: l10n.fullName,
                        hint: l10n.userFullNameHint,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.fullNameRequired
                            : null,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              controller: _username,
                              label: l10n.username,
                              hint: l10n.usernameSignInHint,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.usernameRequired
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _roleField()),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.sectionAccess,
                    children: [
                      _field(
                        controller: _password,
                        label: widget.isEditing
                            ? l10n.newPasswordLabel
                            : l10n.password,
                        hint: widget.isEditing
                            ? l10n.leaveBlankKeep
                            : l10n.passwordMinChars,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (!widget.isEditing && value.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (value.isNotEmpty && value.length < 6) {
                            return l10n.useAtLeast6;
                          }
                          return null;
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l10n.statusActive,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(l10n.inactiveCannotSignIn),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBox(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          widget.isEditing
                              ? l10n.saveChanges
                              : l10n.createUserAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: suffix,
        ),
        validator: validator,
      ),
    );
  }

  bool _isSystemRole(String name) {
    for (final role in _roles) {
      if (role.name.toLowerCase() == name.toLowerCase()) return role.isSystem;
    }
    return false;
  }

  Widget _roleField() {
    final decoration = InputDecoration(
      labelText: context.l10n.roleLabel,
      border: const OutlineInputBorder(),
      isDense: true,
    );
    // Non-admins can't assign system roles (Admin), so hide them from the
    // dropdown — unless the user being edited already holds one (kept visible
    // and read-only so we don't silently change their role on save).
    final isAdmin = context.read<AppSession>().isAdmin;
    final selectable = [
      for (final role in _roles)
        if (isAdmin ||
            !role.isSystem ||
            role.name.toLowerCase() == _role.toLowerCase())
          role,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: !_rolesLoaded || selectable.isEmpty
          ? InputDecorator(
              decoration: decoration,
              child: Text(
                _role,
                style: const TextStyle(color: OperixColors.muted),
              ),
            )
          : DropdownButtonFormField<String>(
              initialValue: _matchRole(selectable, _role),
              decoration: decoration,
              items: [
                for (final role in selectable)
                  DropdownMenuItem(
                    value: role.name,
                    enabled: isAdmin || !role.isSystem,
                    child: Text(role.name),
                  ),
              ],
              onChanged: (value) => setState(() => _role = value ?? _role),
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: OperixColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OperixColors.danger.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OperixColors.danger.withAlpha(70)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: OperixColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: OperixColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
