import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../domain/role_models.dart';
import 'settings_ui.dart';

/// Shows the permissions matrix modal for [role] (or a new role when null).
/// Returns a [RoleDraft] when the user saves, or null when cancelled.
Future<RoleDraft?> showRolePermissionsDialog(
  BuildContext context, {
  Role? role,
}) {
  return showDialog<RoleDraft>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _RolePermissionsDialog(role: role),
  );
}

class _RolePermissionsDialog extends StatefulWidget {
  const _RolePermissionsDialog({this.role});

  final Role? role;

  @override
  State<_RolePermissionsDialog> createState() => _RolePermissionsDialogState();
}

class _RolePermissionsDialogState extends State<_RolePermissionsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final Set<String> _granted;
  late final Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.role?.name ?? '');
    _description = TextEditingController(text: widget.role?.description ?? '');
    _granted = {...?widget.role?.permissions};
    _expanded = {for (final g in kPermissionCatalog) g.key};
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _toggle(String key, bool value) {
    setState(() {
      if (value) {
        _granted.add(key);
      } else {
        _granted.remove(key);
      }
    });
  }

  void _toggleModule(PermissionModule module, bool value) {
    setState(() {
      for (final key in module.permissionKeys) {
        if (value) {
          _granted.add(key);
        } else {
          _granted.remove(key);
        }
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      RoleDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
        permissions: {..._granted},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.of(context).size;
    final title = widget.role == null
        ? l10n.newRoleTitle
        : l10n.permissionsForRole(widget.role!.name);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1040,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(l10n, title),
            const Divider(height: 1, color: OperixColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _identityFields(l10n),
                      const SizedBox(height: 24),
                      for (final group in kPermissionCatalog) ...[
                        _GroupSection(
                          group: group,
                          granted: _granted,
                          expanded: _expanded.contains(group.key),
                          onToggleExpand: () => setState(() {
                            if (!_expanded.remove(group.key)) {
                              _expanded.add(group.key);
                            }
                          }),
                          onToggleAction: _toggle,
                          onToggleModule: _toggleModule,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: OperixColors.border),
            _footer(l10n),
          ],
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: OperixColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.permissionsDialogSubtitle,
                  style: const TextStyle(
                    color: OperixColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: OperixColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _identityFields(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OperixColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _centeredField(
              label: l10n.roleNameLabel,
              controller: _name,
              hint: l10n.roleNameHint,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.roleNameRequired
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _centeredField(
              label: l10n.descriptionLabel,
              controller: _description,
              hint: l10n.descriptionHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Text(label, style: kFieldLabelStyle)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          textAlign: TextAlign.center,
          decoration: kFieldDecoration(hint),
        ),
      ],
    );
  }

  Widget _footer(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: OperixColors.ink,
              side: const BorderSide(color: OperixColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(l10n.cancel),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: OperixColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(l10n.savePermissions),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.granted,
    required this.expanded,
    required this.onToggleExpand,
    required this.onToggleAction,
    required this.onToggleModule,
  });

  final PermissionGroup group;
  final Set<String> granted;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final void Function(String key, bool value) onToggleAction;
  final void Function(PermissionModule module, bool value) onToggleModule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OperixColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggleExpand,
            child: Container(
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.label(context),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: OperixColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    l10n.modulesCount(group.modules.length),
                    style: const TextStyle(
                      color: OperixColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 20,
                    color: OperixColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            for (var i = 0; i < group.modules.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: OperixColors.border),
              _ModuleRow(
                module: group.modules[i],
                granted: granted,
                onToggleAction: onToggleAction,
                onToggleModule: onToggleModule,
              ),
            ],
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.module,
    required this.granted,
    required this.onToggleAction,
    required this.onToggleModule,
  });

  final PermissionModule module;
  final Set<String> granted;
  final void Function(String key, bool value) onToggleAction;
  final void Function(PermissionModule module, bool value) onToggleModule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keys = module.permissionKeys.toList();
    final grantedCount = keys.where(granted.contains).length;
    final allOn = grantedCount == keys.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Right side: module master toggle + name + granted count.
          SizedBox(
            width: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(
                  value: allOn,
                  activeColor: OperixColors.primary,
                  onChanged: (v) => onToggleModule(module, v),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.label(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: OperixColors.ink,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.actionsCount(grantedCount, keys.length),
                        style: const TextStyle(
                          color: OperixColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Left side: individual action toggles.
          Expanded(
            child: Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                for (final action in module.actions)
                  _ActionToggle(
                    label: action.label(context),
                    value: granted.contains(module.permissionKey(action)),
                    onChanged: (v) =>
                        onToggleAction(module.permissionKey(action), v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionToggle extends StatelessWidget {
  const _ActionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Box(
              value: value,
              activeColor: OperixColors.success,
              onChanged: onChanged,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: OperixColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact square checkbox matching the web design.
class _Box extends StatelessWidget {
  const _Box({
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        activeColor: activeColor,
        side: const BorderSide(color: OperixColors.subtle, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
