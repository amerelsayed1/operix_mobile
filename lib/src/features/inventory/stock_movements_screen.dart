import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/operix_theme.dart';
import '../../data/product_repository.dart';
import '../../data/stock_repository.dart';
import '../../domain/inventory_models.dart';
import '../../domain/stock_models.dart';
import '../../domain/value_objects/money.dart';

/// Full-screen stock movement log with a manual-adjustment action.
class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  late final StockRepository _repository;
  late Future<List<StockMovement>> _future;

  @override
  void initState() {
    super.initState();
    _repository = context.read<StockRepository>();
    _future = _repository.recentMovements();
  }

  void _reload() {
    // Block body, not `=> _future = ...`: an arrow returns the assignment value
    // (a Future), which setState rejects — silently skipping the rebuild.
    setState(() {
      _future = _repository.recentMovements();
    });
  }

  Future<void> _adjust() async {
    final applied = await showAdjustStockDialog(context);
    if (applied == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock adjusted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OperixColors.background,
      appBar: AppBar(
        title: const Text('Stock movements'),
        backgroundColor: Colors.white,
        foregroundColor: OperixColors.ink,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: OperixColors.border)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: _adjust,
              icon: const Icon(Icons.tune),
              label: const Text('Adjust stock'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<StockMovement>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load movements: ${snapshot.error}'),
            );
          }
          final movements = snapshot.data ?? const [];
          if (movements.isEmpty) {
            return const Center(
              child: Text(
                'No stock movements yet.',
                style: TextStyle(color: OperixColors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: movements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _MovementTile(movements[index]),
          );
        },
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile(this.movement);

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final up = movement.isIncrease;
    final color = up ? OperixColors.success : OperixColors.danger;
    final date = DateFormat('MMM d, HH:mm').format(movement.createdAt);
    final subtitle = [
      movement.type.label,
      if (movement.reason != null && movement.reason!.isNotEmpty)
        movement.reason,
      date,
    ].join(' • ');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(up ? Icons.south_west : Icons.north_east, color: color),
        ),
        title: Text(
          movement.sku.isEmpty
              ? movement.productName
              : '${movement.productName}  ·  ${movement.sku}',
          style: const TextStyle(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle),
        trailing: Text(
          '${up ? '+' : ''}${movement.quantity}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

/// Adjustment dialog. Returns true when an adjustment was applied. If [product]
/// is given the picker is pre-selected and hidden.
Future<bool?> showAdjustStockDialog(BuildContext context, {Product? product}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _AdjustStockDialog(initialProduct: product),
  );
}

class _AdjustStockDialog extends StatefulWidget {
  const _AdjustStockDialog({this.initialProduct});

  final Product? initialProduct;

  @override
  State<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<_AdjustStockDialog> {
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();

  List<Product> _products = [];
  Product? _selected;
  bool _increase = false; // default: remove stock (the common adjustment)
  String _reason = kAdjustmentReasons.first;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialProduct;
    if (widget.initialProduct == null) {
      _loadProducts();
    } else {
      _products = [widget.initialProduct!];
      _prefillCost();
    }
  }

  /// Seeds the unit-cost field with the product's current average cost so an
  /// "add" adjustment is valued correctly by default (the user can override).
  void _prefillCost() {
    final product = _selected;
    if (product != null && _costController.text.trim().isEmpty) {
      _costController.text = product.costPrice.toStorageString();
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await context.read<ProductRepository>().list();
      if (mounted) setState(() => _products = products);
    } catch (_) {}
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final product = _selected;
    final magnitude = int.tryParse(_qtyController.text.trim());
    if (product == null) {
      setState(() => _error = 'Pick a product.');
      return;
    }
    if (magnitude == null || magnitude <= 0) {
      setState(() => _error = 'Enter a quantity greater than zero.');
      return;
    }
    final delta = _increase ? magnitude : -magnitude;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<StockRepository>().adjust(
        productId: product.id,
        delta: delta,
        reason: _reason,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        userId: context.read<AppSession>().user?.id,
        // Only an "add" carries a cost into inventory; a "remove" relieves at the
        // product's current average cost.
        unitCost: _increase ? Money.parse(_costController.text.trim()) : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on StockException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not adjust stock: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust stock'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.initialProduct == null)
              DropdownButtonFormField<Product>(
                initialValue: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final p in _products)
                    DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.name}  (${p.quantityOnHand})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (p) => setState(() {
                  _selected = p;
                  _costController.text = p?.costPrice.toStorageString() ?? '';
                }),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${widget.initialProduct!.name}  ·  on hand '
                  '${widget.initialProduct!.quantityOnHand}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Remove'),
                  icon: Icon(Icons.remove),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Add'),
                  icon: Icon(Icons.add),
                ),
              ],
              selected: {_increase},
              onSelectionChanged: (s) => setState(() {
                _increase = s.first;
                if (_increase) _prefillCost();
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_increase) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Unit cost',
                  helperText:
                      'Cost the added stock is valued at (weighted in).',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final r in kAdjustmentReasons)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (r) => setState(() => _reason = r ?? _reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: OperixColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _apply,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}
