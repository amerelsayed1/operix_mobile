import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/operix_theme.dart';
import '../../data/returns_repository.dart';
import '../../domain/return_models.dart';
import '../../domain/value_objects/money.dart';

/// Opens the return flow for a POS order. Returns the processed
/// [SalesReturnSummary], or null if cancelled.
Future<SalesReturnSummary?> showReturnDialog(
  BuildContext context, {
  required int orderId,
}) {
  return showDialog<SalesReturnSummary>(
    context: context,
    builder: (context) => _ReturnDialog(orderId: orderId),
  );
}

class _ReturnDialog extends StatefulWidget {
  const _ReturnDialog({required this.orderId});

  final int orderId;

  @override
  State<_ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<_ReturnDialog> {
  late final ReturnsRepository _repository;
  late Future<List<ReturnableLine>> _future;

  final _reasonController = TextEditingController();
  final Map<int, int> _qty = {}; // line index -> quantity to return
  List<ReturnableLine> _lines = [];
  RefundMethod _method = RefundMethod.cash;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = context.read<ReturnsRepository>();
    _future = _load();
  }

  Future<List<ReturnableLine>> _load() async {
    final lines = await _repository.returnableLines(widget.orderId);
    _lines = lines;
    return lines;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Money get _total {
    var total = Money.zero();
    for (var i = 0; i < _lines.length; i++) {
      final q = _qty[i] ?? 0;
      if (q > 0) total = total.add(_lines[i].unitPrice.multiply(q).rounded());
    }
    return total;
  }

  Future<void> _process() async {
    final inputs = <ReturnLineInput>[];
    for (var i = 0; i < _lines.length; i++) {
      final q = _qty[i] ?? 0;
      if (q > 0) {
        inputs.add(
          ReturnLineInput(
            orderItemId: _lines[i].orderItemId,
            productId: _lines[i].productId,
            name: _lines[i].name,
            quantity: q,
            unitPrice: _lines[i].unitPrice,
          ),
        );
      }
    }
    if (inputs.isEmpty) {
      setState(() => _error = 'Select at least one item to return.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final summary = await _repository.createReturn(
        orderId: widget.orderId,
        lines: inputs,
        refundMethod: _method,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        userId: context.read<AppSession>().user?.id,
      );
      if (mounted) Navigator.of(context).pop(summary);
    } on ReturnException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not process the return: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Return items'),
      content: SizedBox(
        width: 480,
        child: FutureBuilder<List<ReturnableLine>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final lines = snapshot.data ?? const [];
            final returnable = lines.where((l) => l.available > 0).toList();
            if (returnable.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nothing left to return on this order.',
                  style: TextStyle(color: OperixColors.muted),
                ),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          if (lines[i].available > 0)
                            _ReturnLineRow(
                              line: lines[i],
                              quantity: _qty[i] ?? 0,
                              onChanged: (q) => setState(() => _qty[i] = q),
                            ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                SegmentedButton<RefundMethod>(
                  segments: const [
                    ButtonSegment(
                      value: RefundMethod.cash,
                      label: Text('Cash refund'),
                      icon: Icon(Icons.payments_outlined),
                    ),
                    ButtonSegment(
                      value: RefundMethod.credit,
                      label: Text('Store credit'),
                      icon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ],
                  selected: {_method},
                  onSelectionChanged: (s) => setState(() => _method = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Refund total',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      formatMoney(_total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: OperixColors.danger),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _process,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.assignment_return_outlined),
          label: const Text('Process return'),
        ),
      ],
    );
  }
}

class _ReturnLineRow extends StatelessWidget {
  const _ReturnLineRow({
    required this.line,
    required this.quantity,
    required this.onChanged,
  });

  final ReturnableLine line;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${formatMoney(line.unitPrice)} • ${line.available} available',
                  style: const TextStyle(
                    color: OperixColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: quantity < line.available
                ? () => onChanged(quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
