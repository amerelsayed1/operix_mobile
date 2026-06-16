import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/operix_theme.dart';
import '../../data/pos_repository.dart';
import '../../domain/pos_models.dart';
import '../../domain/value_objects/money.dart';

/// Shown inside the POS workspace when the cashier has no open shift.
class OpenShiftView extends StatefulWidget {
  const OpenShiftView({super.key});

  @override
  State<OpenShiftView> createState() => _OpenShiftViewState();
}

class _OpenShiftViewState extends State<OpenShiftView> {
  final _floatController = TextEditingController(text: '0');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    final session = context.read<AppSession>();
    final user = session.user;
    if (user == null) return;

    final openingFloat = Money.fromNum(
      double.tryParse(_floatController.text.trim()) ?? 0,
    );
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final shift = await context.read<PosRepository>().openShift(
        cashier: user,
        openingFloat: openingFloat,
      );
      if (!mounted) return;
      session.setShift(shift);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not open shift: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSession>().user;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.point_of_sale,
                  size: 44,
                  color: OperixColors.tealDark,
                ),
                const SizedBox(height: 16),
                Text(
                  'Open a cashier shift',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a shift to begin selling. Cash will be reconciled against '
                  'the opening float when you close it.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: OperixColors.muted),
                ),
                const SizedBox(height: 20),
                if (user != null)
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Cashier: ${user.fullName}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _floatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Opening cash float',
                    prefixText: 'EGP ',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: OperixColors.danger),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _openShift,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_submitting ? 'Opening…' : 'Open shift'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collects the counted cash, closes the shift via the repository, then shows a
/// reconciliation summary. Returns the closed shift (or null if cancelled).
Future<PosShift?> showCloseShiftDialog(
  BuildContext context,
  PosRepository repository,
  PosShift shift,
) {
  return showDialog<PosShift>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _CloseShiftDialog(repository: repository, shift: shift),
  );
}

class _CloseShiftDialog extends StatefulWidget {
  const _CloseShiftDialog({required this.repository, required this.shift});

  final PosRepository repository;
  final PosShift shift;

  @override
  State<_CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<_CloseShiftDialog> {
  final _countedController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _error;
  PosShift? _closed;

  @override
  void dispose() {
    _countedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    final countedRaw = double.tryParse(_countedController.text.trim());
    if (countedRaw == null) {
      setState(() => _error = 'Enter the counted cash amount.');
      return;
    }
    final counted = Money.fromNum(countedRaw);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final closed = await widget.repository.closeShift(
        shift: widget.shift,
        countedCash: counted,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _closed = closed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not close shift: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = _closed;
    if (closed != null) {
      return _ResultDialog(shift: closed);
    }

    return AlertDialog(
      title: Text('Close shift ${widget.shift.shiftNumber}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Opening float', formatMoney(widget.shift.openingFloat)),
            const SizedBox(height: 16),
            TextField(
              controller: _countedController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Counted cash in drawer',
                prefixText: 'EGP ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
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
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _close,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock_outline),
          label: const Text('Close shift'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: OperixColors.muted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.shift});

  final PosShift shift;

  @override
  Widget build(BuildContext context) {
    final difference = shift.cashDifference ?? Money.zero();
    final balanced = difference.isZero;
    final over = difference.isPositive;
    final diffColor = balanced
        ? OperixColors.success
        : over
        ? OperixColors.warning
        : OperixColors.danger;
    final diffLabel = balanced
        ? 'Balanced'
        : over
        ? 'Over by ${formatMoney(difference)}'
        : 'Short by ${formatMoney(difference.abs())}';

    return AlertDialog(
      title: Text('Shift ${shift.shiftNumber} closed'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Opening float', formatMoney(shift.openingFloat)),
            _row(
              'Expected cash',
              formatMoney(shift.expectedCash ?? Money.zero()),
            ),
            _row(
              'Counted cash',
              formatMoney(shift.countedCash ?? Money.zero()),
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: diffColor.withAlpha(22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: diffColor.withAlpha(70)),
              ),
              child: Row(
                children: [
                  Icon(
                    balanced
                        ? Icons.check_circle
                        : Icons.report_problem_outlined,
                    color: diffColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    diffLabel,
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(shift),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OperixColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
