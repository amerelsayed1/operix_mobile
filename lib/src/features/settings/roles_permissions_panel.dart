import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/role_repository.dart';
import '../../domain/role_models.dart';
import 'role_permissions_dialog.dart';
import 'settings_ui.dart';

/// Settings → Roles & permissions. Lists tenant roles with actions to edit a
/// role's permission matrix, rename it or delete it (system roles are locked).
class RolesPermissionsPanel extends StatefulWidget {
  const RolesPermissionsPanel({super.key});

  @override
  State<RolesPermissionsPanel> createState() => _RolesPermissionsPanelState();
}

class _RolesPermissionsPanelState extends State<RolesPermissionsPanel> {
  late RoleRepository _repository;
  late Future<List<Role>> _future;

  @override
  void initState() {
    super.initState();
    _repository = context.read<RoleRepository>();
    _future = _repository.list();
  }

  void _reload() {
    setState(() {
      _future = _repository.list();
    });
  }

  Future<void> _create() async {
    final draft = await showRolePermissionsDialog(context);
    if (draft == null || !mounted) return;
    await _runSave(() => _repository.create(draft), context.l10n.roleCreated);
  }

  Future<void> _edit(Role role) async {
    final draft = await showRolePermissionsDialog(context, role: role);
    if (draft == null || !mounted) return;
    await _runSave(
      () => _repository.update(role.id, draft),
      context.l10n.roleUpdated,
    );
  }

  Future<void> _runSave(Future<Object?> Function() op, String okMessage) async {
    try {
      await op();
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(okMessage)));
      }
    } on RoleException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveRole('$e'))),
        );
      }
    }
  }

  Future<void> _delete(Role role) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.roleDeleteTitle),
        content: Text(l10n.roleDeleteConfirm(role.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: OperixColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(role.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.roleDeleted)));
      }
    } on RoleException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsCard(
      title: l10n.navRolesPermissions,
      subtitle: l10n.rolesSubtitle,
      trailing: FilledButton.icon(
        onPressed: _create,
        icon: const Icon(Icons.add, size: 18),
        label: Text(l10n.addRole),
        style: FilledButton.styleFrom(
          backgroundColor: OperixColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      child: FutureBuilder<List<Role>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.couldNotLoadRoles('${snapshot.error}')),
            );
          }
          final roles = snapshot.data ?? const [];
          return Column(
            children: [
              for (final role in roles)
                _RoleRow(
                  role: role,
                  onPermissions: () => _edit(role),
                  onEdit: () => _edit(role),
                  onDelete: role.isSystem ? null : () => _delete(role),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.onPermissions,
    required this.onEdit,
    required this.onDelete,
  });

  final Role role;
  final VoidCallback onPermissions;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final description = role.description.trim().isEmpty
        ? '—'
        : role.description.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OperixColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: OperixColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$description · ${l10n.membersLabel(role.memberCount)}',
                  style: const TextStyle(
                    color: OperixColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          _PillButton(
            icon: Icons.shield_outlined,
            label: l10n.permissionsAction,
            onTap: onPermissions,
          ),
          const SizedBox(width: 8),
          _PillButton(
            icon: Icons.edit_outlined,
            label: l10n.edit,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _PillButton(
            icon: Icons.delete_outline,
            label: l10n.delete,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? OperixColors.ink : OperixColors.subtle;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: enabled ? OperixColors.border : OperixColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
