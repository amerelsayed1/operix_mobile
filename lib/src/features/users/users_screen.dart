import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/user_admin_repository.dart';
import '../../domain/user_admin_models.dart';
import 'user_form_screen.dart';

/// Localized label for a user role wire value (admin | manager | cashier).
String roleLabel(BuildContext context, String role) {
  final l10n = context.l10n;
  return switch (role) {
    'admin' => l10n.roleAdmin,
    'manager' => l10n.roleManager,
    'cashier' => l10n.roleCashier,
    _ => role,
  };
}

/// Users administration: searchable list + create/edit, with the current user
/// protected from self-deletion.
class UsersScreen extends StatefulWidget {
  const UsersScreen({
    this.autoCreate = false,
    this.onAutoCreateConsumed,
    super.key,
  });

  /// When true, the new-user form opens automatically on arrival (used by the
  /// "Add user" sidebar shortcut).
  final bool autoCreate;
  final VoidCallback? onAutoCreateConsumed;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchController = TextEditingController();
  late UserAdminRepository _repository;
  late Future<List<ManagedUser>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _repository = context.read<UserAdminRepository>();
    _future = _repository.list();
    _maybeAutoCreate();
  }

  @override
  void didUpdateWidget(covariant UsersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoCreate && !oldWidget.autoCreate) _maybeAutoCreate();
  }

  void _maybeAutoCreate() {
    if (!widget.autoCreate) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onAutoCreateConsumed?.call();
      _openForm();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repository.list(search: _search);
    });
  }

  Future<void> _openForm({ManagedUser? user}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserFormScreen(repository: _repository, user: user),
      ),
    );
    if (saved == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user == null
                  ? context.l10n.userCreated
                  : context.l10n.userUpdated,
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(ManagedUser user) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUserTitle),
        content: Text(l10n.deleteConfirmName(user.fullName)),
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
      await _repository.delete(user.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.userDeleted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotDelete('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentUserId = context.watch<AppSession>().user?.id;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.usersTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _search = value;
                    _reload();
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchUsers,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _search = '';
                              _reload();
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(l10n.newUser),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ManagedUser>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(l10n.couldNotLoadUsers('${snapshot.error}')),
                  );
                }
                final users = snapshot.data ?? const [];
                if (users.isEmpty) {
                  return _EmptyUsers(
                    searching: _search.isNotEmpty,
                    onCreate: () => _openForm(),
                  );
                }
                return Card(
                  child: Column(
                    children: [
                      const _HeaderRow(),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _UserRow(
                              user: user,
                              isCurrentUser: user.id == currentUserId,
                              onTap: () => _openForm(user: user),
                              onEdit: () => _openForm(user: user),
                              onDelete: () => _delete(user),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const style = TextStyle(
      fontWeight: FontWeight.w800,
      color: OperixColors.muted,
      fontSize: 12,
    );
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(l10n.colUser, style: style)),
          Expanded(flex: 2, child: Text(l10n.colRole, style: style)),
          Expanded(flex: 3, child: Text(l10n.colLastLogin, style: style)),
          Expanded(flex: 2, child: Text(l10n.colStatus, style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isCurrentUser,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedUser user;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastLogin = user.lastLoginAt == null
        ? l10n.neverLoggedIn
        : DateFormat('MMM d, HH:mm').format(user.lastLoginAt!.toLocal());
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        _Pill(label: l10n.youPill, color: OperixColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: OperixColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                roleLabel(context, user.role),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: user.isAdmin
                      ? OperixColors.tealDark
                      : OperixColors.ink,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                lastLogin,
                style: const TextStyle(color: OperixColors.muted),
              ),
            ),
            Expanded(
              flex: 2,
              child: _Pill(
                label: user.isActive ? l10n.statusActive : l10n.statusInactive,
                color: user.isActive
                    ? OperixColors.success
                    : OperixColors.muted,
              ),
            ),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.edit),
                    ),
                  ),
                  if (!isCurrentUser)
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline),
                        title: Text(l10n.delete),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers({required this.searching, required this.onCreate});

  final bool searching;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (searching) {
      return Center(
        child: Text(
          l10n.noUsersMatch,
          style: const TextStyle(color: OperixColors.muted),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.manage_accounts_outlined,
            size: 52,
            color: OperixColors.subtle,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noUsersYet,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noUsersSubtitle,
            style: const TextStyle(color: OperixColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.newUser),
          ),
        ],
      ),
    );
  }
}
