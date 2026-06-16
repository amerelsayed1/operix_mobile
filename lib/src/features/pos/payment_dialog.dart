import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../domain/pos_models.dart';
import '../../domain/value_objects/money.dart';

/// Result returned from [showPaymentDialog].
class PaymentOutcome {
  const PaymentOutcome({
    required this.payments,
    required this.paidAmount,
    required this.changeAmount,
  });

  /// The tenders as the customer handed them over — their amounts sum to
  /// [paidAmount]. Cash change is reported separately in [changeAmount] (and is
  /// reconciled out of the drawer at shift close), never folded into a tender.
  final List<PosPayment> payments;

  /// Total amount the customer handed over (may exceed the total for cash).
  final Money paidAmount;

  /// Change owed back to the customer.
  final Money changeAmount;
}

class _Tender {
  _Tender({
    required this.method,
    required this.amount,
    this.label,
    this.reference,
  });
  final PaymentMethod method;
  final Money amount;
  final String? label;
  final String? reference;
}

String _methodLabel(BuildContext context, PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return context.l10n.cash;
    case PaymentMethod.card:
      return context.l10n.card;
    case PaymentMethod.custom:
      return context.l10n.custom;
  }
}

Future<PaymentOutcome?> showPaymentDialog(BuildContext context, Money total) {
  return showDialog<PaymentOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PaymentDialog(total: total),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.total});

  final Money total;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final List<_Tender> _tenders = [];
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  final _referenceController = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;

  Money get _nonCashTendered => sumMoney(
    _tenders.where((t) => t.method != PaymentMethod.cash).map((t) => t.amount),
  );

  Money get _totalTendered => sumMoney(_tenders.map((t) => t.amount));

  Money get _remaining {
    final diff = widget.total.subtract(_totalTendered);
    return diff.isNegative ? Money.zero() : diff;
  }

  Money get _change {
    final diff = _totalTendered.subtract(widget.total);
    return diff.isNegative ? Money.zero() : diff;
  }

  bool get _isCovered => _totalTendered >= widget.total;

  @override
  void initState() {
    super.initState();
    _resetAmountToRemaining();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _resetAmountToRemaining() {
    final due = widget.total.subtract(_totalTendered);
    _amountController.text = due.isPositive ? _trim(due) : '';
  }

  String _trim(Money v) {
    final s = v.toStorageString();
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  void _addTender() {
    final l10n = context.l10n;
    final text = _amountController.text.trim();
    final raw = double.tryParse(text);
    if (raw == null || raw <= 0) {
      _toast(l10n.enterValidAmount);
      return;
    }
    // Build the amount from the exact decimal string rather than the parsed
    // double, so user input never round-trips through binary floating point.
    final amount = Money.parse(text);
    if (_method != PaymentMethod.cash && amount > _remaining) {
      _toast(
        l10n.cannotExceedRemaining(
          _methodLabel(context, _method),
          formatMoney(_remaining),
        ),
      );
      return;
    }
    if (_method == PaymentMethod.custom &&
        _labelController.text.trim().isEmpty) {
      _toast(l10n.nameCustomMethod);
      return;
    }
    setState(() {
      _tenders.add(
        _Tender(
          method: _method,
          amount: amount,
          label: _method == PaymentMethod.custom
              ? _labelController.text.trim()
              : null,
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
        ),
      );
      _labelController.clear();
      _referenceController.clear();
      _resetAmountToRemaining();
    });
  }

  void _removeTender(int index) {
    setState(() {
      _tenders.removeAt(index);
      _resetAmountToRemaining();
    });
  }

  void _confirm() {
    if (!_isCovered) return;
    final nonCash = _tenders
        .where((t) => t.method != PaymentMethod.cash)
        .toList();
    final payments = <PosPayment>[
      for (final t in nonCash)
        PosPayment(
          method: t.method,
          amount: t.amount,
          label: t.label,
          reference: t.reference,
        ),
    ];
    // Record the cash actually handed over (gross), not the net-of-change
    // amount, so the payment lines sum to paidAmount and the receipt reconciles.
    // Change is reported separately and is subtracted from the drawer when the
    // shift is closed.
    final cashTendered = _totalTendered.subtract(_nonCashTendered);
    if (cashTendered.isPositive) {
      payments.add(
        PosPayment(method: PaymentMethod.cash, amount: cashTendered),
      );
    }
    Navigator.of(context).pop(
      PaymentOutcome(
        payments: payments,
        paidAmount: _totalTendered,
        changeAmount: _change,
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  List<Money> get _quickCash {
    final due = widget.total.subtract(_totalTendered);
    if (!due.isPositive) return const [];
    final d = due.toDouble();
    final suggestions = <double>{
      d,
      (d / 50).ceil() * 50.0,
      (d / 100).ceil() * 100.0,
      ((d / 100).ceil() * 100.0) + 100,
    };
    return suggestions.where((v) => v >= d).map(Money.fromNum).toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.takePayment),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryHeader(
                total: widget.total,
                paid: _totalTendered,
                remaining: _remaining,
                change: _change,
                covered: _isCovered,
              ),
              const SizedBox(height: 18),
              SegmentedButton<PaymentMethod>(
                segments: [
                  ButtonSegment(
                    value: PaymentMethod.cash,
                    label: Text(l10n.cash),
                    icon: const Icon(Icons.payments_outlined),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.card,
                    label: Text(l10n.card),
                    icon: const Icon(Icons.credit_card),
                  ),
                  ButtonSegment(
                    value: PaymentMethod.custom,
                    label: Text(l10n.custom),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (selected) {
                  setState(() {
                    _method = selected.first;
                    if (_method != PaymentMethod.cash) {
                      _amountController.text = _remaining.isPositive
                          ? _trim(_remaining)
                          : '';
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              if (_method == PaymentMethod.custom) ...[
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: l10n.methodNameHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        prefixText: 'EGP ',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTender(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        labelText: l10n.referenceOptional,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              if (_method == PaymentMethod.cash && _quickCash.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amount in _quickCash)
                      ActionChip(
                        label: Text(formatMoney(amount)),
                        onPressed: () {
                          _amountController.text = _trim(amount);
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _addTender,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addPayment),
                ),
              ),
              if (_tenders.isNotEmpty) ...[
                const Divider(height: 24),
                for (var i = 0; i < _tenders.length; i++)
                  _TenderRow(
                    tender: _tenders[i],
                    onRemove: () => _removeTender(i),
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _isCovered ? _confirm : null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            _change.isPositive
                ? l10n.confirmChange(formatMoney(_change))
                : l10n.confirmPayment,
          ),
        ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.total,
    required this.paid,
    required this.remaining,
    required this.change,
    required this.covered,
  });

  final Money total;
  final Money paid;
  final Money remaining;
  final Money change;
  final bool covered;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OperixColors.night,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalDue,
                style: const TextStyle(color: OperixColors.subtle),
              ),
              Text(
                formatMoney(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  l10n.paid,
                  formatMoney(paid),
                  OperixColors.teal,
                ),
              ),
              Expanded(
                child: covered
                    ? _miniStat(
                        l10n.change,
                        formatMoney(change),
                        OperixColors.teal,
                      )
                    : _miniStat(
                        l10n.remaining,
                        formatMoney(remaining),
                        const Color(0xFFFBBF24),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: OperixColors.subtle, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TenderRow extends StatelessWidget {
  const _TenderRow({required this.tender, required this.onRemove});

  final _Tender tender;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = switch (tender.method) {
      PaymentMethod.cash => Icons.payments_outlined,
      PaymentMethod.card => Icons.credit_card,
      PaymentMethod.custom => Icons.account_balance_wallet_outlined,
    };
    final display = tender.method == PaymentMethod.custom
        ? (tender.label?.trim().isNotEmpty == true
              ? tender.label!.trim()
              : context.l10n.custom)
        : _methodLabel(context, tender.method);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: OperixColors.tealDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (tender.reference != null)
                  Text(
                    tender.reference!,
                    style: const TextStyle(
                      color: OperixColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            formatMoney(tender.amount),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: OperixColors.danger,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
