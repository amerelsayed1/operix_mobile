import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/operix_theme.dart';
import '../../data/returns_repository.dart';
import '../../domain/return_models.dart';

/// Lists recent sales returns from the repository. Replaces the old hardcoded
/// dashboard mock. Returns themselves are created from the POS receipt screen.
class SalesReturnsScreen extends StatefulWidget {
  const SalesReturnsScreen({super.key});

  @override
  State<SalesReturnsScreen> createState() => _SalesReturnsScreenState();
}

class _SalesReturnsScreenState extends State<SalesReturnsScreen> {
  late ReturnsRepository _repository;
  late Future<List<SalesReturnSummary>> _future;

  @override
  void initState() {
    super.initState();
    _repository = context.read<ReturnsRepository>();
    _future = _repository.recentReturns();
  }

  void _reload() {
    setState(() {
      _future = _repository.recentReturns();
    });
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
                'Sales returns',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SalesReturnSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load returns: ${snapshot.error}'),
                  );
                }
                final returns = snapshot.data ?? const [];
                if (returns.isEmpty) {
                  return const _EmptyReturns();
                }
                return Card(
                  child: Column(
                    children: [
                      const _HeaderRow(),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: returns.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) =>
                              _ReturnRow(summary: returns[index]),
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
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('RETURN', style: style)),
          Expanded(flex: 3, child: Text('DATE', style: style)),
          Expanded(flex: 2, child: Text('ORDER', style: style)),
          Expanded(flex: 2, child: Text('REFUND', style: style)),
          Expanded(flex: 2, child: Text('AMOUNT', style: style)),
        ],
      ),
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({required this.summary});

  final SalesReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, HH:mm').format(summary.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              summary.returnNumber,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              date,
              style: const TextStyle(color: OperixColors.muted),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              summary.posOrderId == null ? '—' : '#${summary.posOrderId}',
            ),
          ),
          Expanded(flex: 2, child: Text(summary.refundMethod.label)),
          Expanded(
            flex: 2,
            child: Text(
              formatMoney(summary.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReturns extends StatelessWidget {
  const _EmptyReturns();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 52,
            color: OperixColors.subtle,
          ),
          SizedBox(height: 14),
          Text(
            'No returns yet',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Process a return from a sale’s receipt to see it here.',
            style: TextStyle(color: OperixColors.muted),
          ),
        ],
      ),
    );
  }
}
