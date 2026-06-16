import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/supplier_repository.dart';
import '../../domain/supplier_models.dart';
import 'supplier_form_screen.dart';

/// Suppliers management for the Suppliers module: searchable list + create/edit.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({
    this.autoCreate = false,
    this.onAutoCreateConsumed,
    super.key,
  });

  /// When true, the new-supplier form opens automatically on arrival (used by
  /// the "Add supplier" sidebar shortcut).
  final bool autoCreate;
  final VoidCallback? onAutoCreateConsumed;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchController = TextEditingController();
  late SupplierRepository _repository;
  late Future<List<Supplier>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _repository = context.read<SupplierRepository>();
    _future = _repository.list();
    _maybeAutoCreate();
  }

  @override
  void didUpdateWidget(covariant SuppliersScreen oldWidget) {
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

  Future<void> _openForm({Supplier? supplier}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          SupplierFormDialog(repository: _repository, supplier: supplier),
    );
    if (saved == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              supplier == null
                  ? context.l10n.supplierCreated
                  : context.l10n.supplierUpdated,
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(Supplier supplier) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSupplierTitle),
        content: Text(l10n.deleteConfirmName(supplier.companyName)),
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
      await _repository.delete(supplier.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.supplierDeleted)));
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.suppliersTitle,
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
                    hintText: l10n.searchSuppliers,
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
                label: Text(l10n.newSupplier),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Supplier>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n.couldNotLoadSuppliers('${snapshot.error}'),
                    ),
                  );
                }
                final suppliers = snapshot.data ?? const [];
                if (suppliers.isEmpty) {
                  return _EmptySuppliers(
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
                          itemCount: suppliers.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final supplier = suppliers[index];
                            return _SupplierRow(
                              supplier: supplier,
                              onTap: () => _openForm(supplier: supplier),
                              onEdit: () => _openForm(supplier: supplier),
                              onDelete: () => _delete(supplier),
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
          Expanded(flex: 4, child: Text(l10n.colSupplier, style: style)),
          Expanded(flex: 3, child: Text(l10n.colPhone, style: style)),
          Expanded(flex: 2, child: Text(l10n.colPayable, style: style)),
          Expanded(flex: 2, child: Text(l10n.colStatus, style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.supplier,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  Text(
                    supplier.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supplier.code,
                    style: const TextStyle(
                      color: OperixColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                (supplier.phone == null || supplier.phone!.isEmpty)
                    ? '—'
                    : supplier.phone!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatMoney(supplier.balance),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: supplier.isOwed
                      ? OperixColors.warning
                      : OperixColors.ink,
                ),
              ),
            ),
            Expanded(flex: 2, child: _StatusTag(status: supplier.status)),
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

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final SupplierStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, label) = switch (status) {
      SupplierStatus.active => (OperixColors.success, l10n.statusActive),
      SupplierStatus.inactive => (OperixColors.muted, l10n.statusInactive),
      SupplierStatus.blocked => (OperixColors.danger, l10n.statusBlocked),
    };
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

class _EmptySuppliers extends StatelessWidget {
  const _EmptySuppliers({required this.searching, required this.onCreate});

  final bool searching;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (searching) {
      return Center(
        child: Text(
          l10n.noSuppliersMatch,
          style: const TextStyle(color: OperixColors.muted),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 52,
            color: OperixColors.subtle,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noSuppliersYet,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noSuppliersSubtitle,
            style: const TextStyle(color: OperixColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.newSupplier),
          ),
        ],
      ),
    );
  }
}
