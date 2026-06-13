import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/operix_theme.dart';
import '../../data/pos_repository.dart';
import '../../domain/pos_models.dart';
import 'receipt_view.dart';

/// Lists recent POS orders. [refreshTick] can be bumped by the parent to force a
/// reload after a new sale.
class SalesHistoryView extends StatefulWidget {
  const SalesHistoryView({
    required this.repository,
    required this.shiftId,
    this.refreshTick = 0,
    super.key,
  });

  final PosRepository repository;
  final int? shiftId;
  final int refreshTick;

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  late Future<List<PosOrderSummary>> _future;
  bool _shiftOnly = true;
  int? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(SalesHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _reload();
    }
  }

  Future<List<PosOrderSummary>> _load() {
    return widget.repository.recentOrders(
      shiftId: _shiftOnly ? widget.shiftId : null,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openReceipt(PosOrderSummary order) async {
    setState(() => _busyOrderId = order.id);
    try {
      final receipt = await widget.repository.orderReceipt(order.id);
      if (!mounted) return;
      await showReceiptDialog(context, receipt);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open receipt: $e')));
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
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
                'Sales history',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (widget.shiftId != null)
                Row(
                  children: [
                    const Text('This shift only'),
                    Switch(
                      value: _shiftOnly,
                      onChanged: (value) {
                        setState(() {
                          _shiftOnly = value;
                          _future = _load();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<PosOrderSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load orders: ${snapshot.error}'),
                  );
                }
                final orders = snapshot.data ?? const [];
                if (orders.isEmpty) {
                  return const _EmptyHistory();
                }
                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderTile(
                        order: order,
                        busy: _busyOrderId == order.id,
                        onTap: () => _openReceipt(order),
                      );
                    },
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

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.busy,
    required this.onTap,
  });

  final PosOrderSummary order;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d, HH:mm').format(order.createdAt);
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE0F2F1),
        child: Icon(Icons.receipt_long, color: OperixColors.tealDark),
      ),
      title: Text(
        order.receiptNumber,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '$time • ${order.itemCount} item(s) • ${_methods(order.paymentSummary)}',
      ),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              formatEgp(order.total),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
      onTap: busy ? null : onTap,
    );
  }

  String _methods(String raw) {
    if (raw.isEmpty) return 'No payment';
    return raw
        .split('+')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' + ');
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: OperixColors.muted,
          ),
          SizedBox(height: 12),
          Text(
            'No sales yet',
            style: TextStyle(
              color: OperixColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
