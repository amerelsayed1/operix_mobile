import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/operix_theme.dart';
import '../../data/business_repository.dart';
import '../../domain/business_profile.dart';
import '../../domain/pos_models.dart';

/// A compact, thermal-receipt-style preview of a persisted order.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    required this.receipt,
    this.storeName = 'Operix Store',
    this.storeLogoPath,
    super.key,
  });

  final PosReceipt receipt;
  final String storeName;
  final String? storeLogoPath;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d yyyy • HH:mm');
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OperixColors.border),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: OperixColors.ink,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReceiptLogo(logoPath: storeLogoPath),
            Center(
              child: Text(
                storeName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(child: Text('Sales Receipt')),
            const SizedBox(height: 12),
            _dashed(),
            const SizedBox(height: 8),
            _kv('Receipt', receipt.receiptNumber),
            _kv('Date', dateFormat.format(receipt.createdAt)),
            _kv('Cashier', receipt.cashierName),
            if (receipt.customerName != null &&
                receipt.customerName!.isNotEmpty)
              _kv('Customer', receipt.customerName!),
            const SizedBox(height: 8),
            _dashed(),
            const SizedBox(height: 8),
            for (final line in receipt.lines) _ReceiptLineRow(line: line),
            const SizedBox(height: 8),
            _dashed(),
            const SizedBox(height: 8),
            _amount('Subtotal', receipt.subtotal),
            if (receipt.discount > 0) _amount('Discount', -receipt.discount),
            if (receipt.tax > 0) _amount('Tax', receipt.tax),
            const SizedBox(height: 4),
            _amount('TOTAL', receipt.total, strong: true),
            const SizedBox(height: 8),
            _dashed(),
            const SizedBox(height: 8),
            for (final payment in receipt.payments)
              _amount(payment.displayLabel, payment.amount),
            if (receipt.changeAmount > 0)
              _amount('Change', receipt.changeAmount),
            const SizedBox(height: 14),
            const Center(child: Text('Thank you for your purchase!')),
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(key)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _amount(String label, double value, {bool strong = false}) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: strong ? 15 : 13,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatEgp(value), style: style),
        ],
      ),
    );
  }

  Widget _dashed() => const Text(
    '--------------------------------',
    maxLines: 1,
    overflow: TextOverflow.clip,
    style: TextStyle(fontFamily: 'monospace', color: OperixColors.muted),
  );
}

class _ReceiptLogo extends StatelessWidget {
  const _ReceiptLogo({this.logoPath});

  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    final path = logoPath?.trim();
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Image.file(
          File(path),
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ReceiptLineRow extends StatelessWidget {
  const _ReceiptLineRow({required this.line});

  final ReceiptLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.name),
          Row(
            children: [
              Expanded(
                child: Text(
                  '  ${line.quantity} x ${formatEgp(line.unitPrice)}',
                  style: const TextStyle(color: OperixColors.muted),
                ),
              ),
              Text(formatEgp(line.lineTotal)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows a receipt in a dialog with a close action.
Future<void> showReceiptDialog(BuildContext context, PosReceipt receipt) {
  final profileFuture = context.read<BusinessRepository>().loadProfile();
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<BusinessProfile?>(
              future: profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return ReceiptCard(
                  receipt: receipt,
                  storeName: profile?.businessName ?? 'Operix Store',
                  storeLogoPath: profile?.logoPath,
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}
