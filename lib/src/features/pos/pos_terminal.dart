import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/pos_repository.dart';
import '../../domain/pos_models.dart';
import 'payment_dialog.dart';
import 'pos_controller.dart';
import 'receipt_view.dart';

/// The selling surface: searchable product grid on the left, live cart on the
/// right. Expects a [PosController] above it in the tree.
class PosTerminal extends StatefulWidget {
  const PosTerminal({required this.onSaleComplete, super.key});

  final VoidCallback onSaleComplete;

  @override
  State<PosTerminal> createState() => _PosTerminalState();
}

class _PosTerminalState extends State<PosTerminal> {
  final _searchController = TextEditingController();
  final _customerController = TextEditingController();
  bool _charging = false;

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _charge(PosController controller) async {
    if (controller.isCartEmpty || _charging) return;
    final session = context.read<AppSession>();
    final user = session.user;
    final shift = session.shift;
    if (user == null || shift == null) return;
    final checkoutFailed = context.l10n.checkoutFailed;

    final outcome = await showPaymentDialog(context, controller.total);
    if (outcome == null || !mounted) return;

    setState(() => _charging = true);
    PosReceipt? receipt;
    try {
      receipt = await controller.checkout(
        cashier: user,
        shift: shift,
        payments: outcome.payments,
        paidAmount: outcome.paidAmount,
        changeAmount: outcome.changeAmount,
        customerName: _customerController.text.trim().isEmpty
            ? null
            : _customerController.text.trim(),
      );
      _customerController.clear();
      widget.onSaleComplete();
    } on InsufficientStockException catch (e) {
      _notify(e.message);
    } on PosException catch (e) {
      _notify(e.message);
    } catch (e) {
      _notify(checkoutFailed('$e'));
    } finally {
      if (mounted) setState(() => _charging = false);
    }

    // Show the receipt only after the spinner is cleared.
    if (receipt != null && mounted) {
      await showReceiptDialog(context, receipt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PosController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _catalog(controller)),
        const VerticalDivider(width: 1),
        SizedBox(width: 380, child: _cartPanel(controller)),
      ],
    );
  }

  Widget _catalog(PosController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: TextField(
            controller: _searchController,
            onChanged: controller.setSearch,
            decoration: InputDecoration(
              hintText: context.l10n.searchProductsHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: controller.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearch('');
                      },
                    ),
            ),
          ),
        ),
        _categoryBar(controller),
        Expanded(child: _grid(controller)),
      ],
    );
  }

  Widget _categoryBar(PosController controller) {
    final categories = controller.categories;
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(context.l10n.all),
              selected: controller.category == null,
              onSelected: (_) => controller.setCategory(null),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: controller.category == category,
                onSelected: (_) => controller.setCategory(category),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(PosController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return Center(child: Text(controller.error!));
    }
    final products = controller.visibleProducts;
    if (products.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noProductsMatchSearch,
          style: const TextStyle(color: OperixColors.muted),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        mainAxisExtent: 132,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          available: controller.availableFor(product),
          onTap: () {
            if (!controller.addProduct(product)) {
              _notify(context.l10n.noMoreStock(product.name));
            }
          },
        );
      },
    );
  }

  Widget _cartPanel(PosController controller) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.currentSale,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  context.l10n.itemCount(controller.cartItemCount),
                  style: const TextStyle(color: OperixColors.muted),
                ),
                IconButton(
                  tooltip: context.l10n.clearCart,
                  onPressed: controller.isCartEmpty
                      ? null
                      : controller.clearCart,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              controller: _customerController,
              decoration: InputDecoration(
                labelText: context.l10n.customerOptional,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: controller.isCartEmpty
                ? const _EmptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: controller.cart.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final line = controller.cart[index];
                      return _CartRow(
                        line: line,
                        onIncrement: () {
                          if (!controller.increment(line)) {
                            _notify(context.l10n.noMoreStock(line.product.name));
                          }
                        },
                        onDecrement: () => controller.decrement(line),
                        onRemove: () => controller.removeLine(line),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          _summary(controller),
        ],
      ),
    );
  }

  Widget _summary(PosController controller) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _amountRow(l10n.subtotal, controller.subtotal),
          Row(
            children: [
              Expanded(
                child: _amountRow(l10n.discount, -controller.discountAmount),
              ),
              TextButton(
                onPressed: () => _editDiscount(controller),
                child: Text(controller.discount > 0 ? l10n.edit : l10n.addAction),
              ),
            ],
          ),
          if (PosController.taxRate > 0)
            _amountRow(l10n.tax, controller.taxAmount),
          const Divider(height: 20),
          _amountRow(l10n.total, controller.total, strong: true),
          const SizedBox(height: 14),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: controller.isCartEmpty || _charging
                  ? null
                  : () => _charge(controller),
              icon: _charging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.point_of_sale),
              label: Text(
                _charging
                    ? l10n.saving
                    : l10n.chargeAmount(formatEgp(controller.total)),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDiscount(PosController controller) async {
    final textController = TextEditingController(
      text: controller.discount > 0
          ? controller.discount.toStringAsFixed(0)
          : '',
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.orderDiscount),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: context.l10n.discountAmount,
            prefixText: 'EGP ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: Text(context.l10n.clear),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              double.tryParse(textController.text.trim()) ?? 0.0,
            ),
            child: Text(context.l10n.apply),
          ),
        ],
      ),
    );
    if (value != null) controller.setDiscount(value);
  }

  Widget _amountRow(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? OperixColors.ink : OperixColors.muted,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatEgp(value),
            style: TextStyle(
              fontSize: strong ? 20 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.available,
    required this.onTap,
  });

  final PosProduct product;
  final int available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = available <= 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: outOfStock ? null : onTap,
        child: Opacity(
          opacity: outOfStock ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: OperixColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: OperixColors.tealDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatEgp(product.unitPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: OperixColors.ink,
                        ),
                      ),
                    ),
                    _StockBadge(available: available),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.available});

  final int available;

  @override
  Widget build(BuildContext context) {
    final color = available <= 0
        ? OperixColors.danger
        : available <= 5
        ? OperixColors.warning
        : OperixColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        available <= 0 ? context.l10n.outBadge : '$available',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  formatEgp(line.product.unitPrice),
                  style: const TextStyle(
                    color: OperixColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _QtyStepper(
            quantity: line.quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(
              formatEgp(line.lineTotal),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: OperixColors.muted,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: OperixColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _btn(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: OperixColors.tealDark),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 44,
            color: OperixColors.subtle,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.cartEmpty,
            style: const TextStyle(
              color: OperixColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.tapProductsToAdd,
            style: const TextStyle(color: OperixColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
