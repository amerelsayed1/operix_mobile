import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/operix_theme.dart';
import '../../data/sales_report_repository.dart';
import '../../domain/report_models.dart';

/// Operational sales reporting: pick a period and see revenue, transaction
/// count, average sale, estimated profit, top products and the payment mix.
class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late final SalesReportRepository _repository;
  late Future<SalesReport> _future;

  ReportRange _range = ReportRange.today;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    _repository = context.read<SalesReportRepository>();
    _future = _load();
  }

  ({DateTime from, DateTime to}) _window() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endExclusive = startOfToday.add(const Duration(days: 1));
    switch (_range) {
      case ReportRange.today:
        return (from: startOfToday, to: endExclusive);
      case ReportRange.week:
        // Monday of the current week → tomorrow.
        final monday = startOfToday.subtract(Duration(days: now.weekday - 1));
        return (from: monday, to: endExclusive);
      case ReportRange.month:
        return (from: DateTime(now.year, now.month), to: endExclusive);
      case ReportRange.custom:
        final from = _customFrom ?? startOfToday;
        final to = (_customTo ?? startOfToday).add(const Duration(days: 1));
        return (from: from, to: to);
    }
  }

  Future<SalesReport> _load() {
    final w = _window();
    return _repository.generate(from: w.from, to: w.to);
  }

  void _selectRange(ReportRange range) {
    setState(() {
      _range = range;
      _future = _load();
    });
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : null,
    );
    if (picked == null) return;
    setState(() {
      _customFrom = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _customTo = DateTime(picked.end.year, picked.end.month, picked.end.day);
      _range = ReportRange.custom;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _rangeBar(),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<SalesReport>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load report: ${snapshot.error}'),
                  );
                }
                final report = snapshot.requireData;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MetricGrid(report: report),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _TopProductsCard(report: report),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _PaymentMixCard(report: report),
                          ),
                        ],
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

  Widget _rangeBar() {
    final df = DateFormat('MMM d');
    final w = _window();
    final label = _range == ReportRange.custom && _customFrom != null
        ? '${df.format(w.from)} – ${df.format(w.to.subtract(const Duration(days: 1)))}'
        : null;
    return Row(
      children: [
        Text(
          'Sales reports',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        for (final r in ReportRange.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: r == ReportRange.custom
                ? ActionChip(
                    avatar: const Icon(Icons.event, size: 18),
                    label: Text(label ?? r.label),
                    onPressed: _pickCustom,
                    backgroundColor: _range == ReportRange.custom
                        ? const Color(0xFFE0F2F1)
                        : null,
                  )
                : ChoiceChip(
                    label: Text(r.label),
                    selected: _range == r,
                    onSelected: (_) => _selectRange(r),
                  ),
          ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    final profit = report.estimatedProfit;
    return Row(
      children: [
        _metric('Revenue', formatMoney(report.totalRevenue), OperixColors.teal),
        const SizedBox(width: 16),
        _metric(
          'Transactions',
          '${report.transactionCount}',
          OperixColors.primary,
        ),
        const SizedBox(width: 16),
        _metric(
          'Avg. sale',
          formatMoney(report.averageSale),
          const Color(0xFF6366F1),
        ),
        const SizedBox(width: 16),
        _metric(
          'Est. profit',
          formatMoney(profit),
          profit.isNegative ? OperixColors.danger : OperixColors.success,
        ),
      ],
    );
  }

  Widget _metric(String label, String value, Color tone) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: OperixColors.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    final products = report.topProducts;
    final maxQty = products.isEmpty
        ? 1
        : products.map((p) => p.quantity).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Top products',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No sales in this period.',
                    style: TextStyle(color: OperixColors.muted),
                  ),
                ),
              )
            else
              for (final p in products)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${p.quantity} • ${formatMoney(p.revenue)}',
                            style: const TextStyle(
                              color: OperixColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.quantity / maxQty,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          color: OperixColors.teal,
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

class _PaymentMixCard extends StatelessWidget {
  const _PaymentMixCard({required this.report});

  final SalesReport report;

  String _label(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'custom':
        return 'Custom';
      default:
        return method.isEmpty ? 'Other' : method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = report.paymentBreakdown;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'By payment method',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No payments in this period.',
                    style: TextStyle(color: OperixColors.muted),
                  ),
                ),
              )
            else
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_label(r.method)}  (${r.count})',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        formatMoney(r.amount),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            const Divider(height: 24),
            const Text(
              'Profit is estimated from current product cost prices.',
              style: TextStyle(color: OperixColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
