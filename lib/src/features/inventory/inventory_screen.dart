import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/product_repository.dart';
import '../../domain/inventory_models.dart';
import 'product_form_screen.dart';
import 'stock_movements_screen.dart';

/// Products management for the Inventory module: searchable list + create/edit.
class InventoryProductsScreen extends StatefulWidget {
  const InventoryProductsScreen({super.key});

  @override
  State<InventoryProductsScreen> createState() =>
      _InventoryProductsScreenState();
}

class _InventoryProductsScreenState extends State<InventoryProductsScreen> {
  final _searchController = TextEditingController();
  late ProductRepository _repository;
  late Future<List<Product>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _repository = context.read<ProductRepository>();
    _future = _repository.list();
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

  Future<void> _openForm({Product? product}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ProductFormScreen(repository: _repository, product: product),
      ),
    );
    if (saved == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product == null
                  ? context.l10n.productCreated
                  : context.l10n.productUpdated,
            ),
          ),
        );
      }
    }
  }

  void _openStockLog() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StockMovementsScreen()));
  }

  Future<void> _adjustStock(Product product) async {
    final applied = await showAdjustStockDialog(context, product: product);
    if (applied == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.stockAdjusted)));
      }
    }
  }

  Future<void> _delete(Product product) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProductTitle),
        content: Text(l10n.deleteConfirmName(product.name)),
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
      await _repository.delete(product.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.productDeleted)));
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                context.l10n.products,
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
                    hintText: context.l10n.searchProducts,
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
              OutlinedButton.icon(
                onPressed: _openStockLog,
                icon: const Icon(Icons.inventory_outlined),
                label: Text(context.l10n.stockLog),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.newProduct),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      context.l10n.couldNotLoadProducts(snapshot.error ?? ''),
                    ),
                  );
                }
                final products = snapshot.data ?? const [];
                if (products.isEmpty) {
                  return _EmptyProducts(
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
                          itemCount: products.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductRow(
                              product: product,
                              onTap: () => _openForm(product: product),
                              onEdit: () => _openForm(product: product),
                              onAdjust: () => _adjustStock(product),
                              onDelete: () => _delete(product),
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
    const style = TextStyle(
      fontWeight: FontWeight.w800,
      color: OperixColors.muted,
      fontSize: 12,
    );
    final l10n = context.l10n;
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(l10n.colProduct, style: style)),
          Expanded(flex: 2, child: Text(l10n.colCategory, style: style)),
          Expanded(flex: 2, child: Text(l10n.colStock, style: style)),
          Expanded(flex: 2, child: Text(l10n.colPrice, style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onAdjust,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (!product.isActive) ...[
                        const SizedBox(width: 8),
                        _Tag(
                          label: context.l10n.tagInactive,
                          color: OperixColors.muted,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.sku} • ${product.unit}',
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
                product.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(
                    '${product.quantityOnHand}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (product.isLowStock) ...[
                    const SizedBox(width: 6),
                    _Tag(
                      label: context.l10n.tagLow,
                      color: OperixColors.warning,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatMoney(product.sellingPrice),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'adjust':
                      onAdjust();
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
                      title: Text(context.l10n.edit),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'adjust',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tune),
                      title: Text(context.l10n.adjustStock),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline),
                      title: Text(context.l10n.delete),
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.searching, required this.onCreate});

  final bool searching;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (searching) {
      return Center(
        child: Text(
          l10n.noProductsMatch,
          style: const TextStyle(color: OperixColors.muted),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 52,
            color: OperixColors.subtle,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noProductsYet,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.createFirstProductHint,
            style: const TextStyle(color: OperixColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.newProduct),
          ),
        ],
      ),
    );
  }
}
