// Operational sales-report models (period revenue, top products, payment mix).
// Distinct from the GL financial reports (trial balance / P&L) — these read the
// POS order tables directly. Kept free of Flutter / database imports.

import 'value_objects/money.dart';

/// A preset reporting window.
enum ReportRange { today, week, month, custom }

extension ReportRangeX on ReportRange {
  String get label {
    switch (this) {
      case ReportRange.today:
        return 'Today';
      case ReportRange.week:
        return 'This week';
      case ReportRange.month:
        return 'This month';
      case ReportRange.custom:
        return 'Custom';
    }
  }
}

/// A product line in the "top products" ranking.
class TopProduct {
  const TopProduct({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final String sku;
  final int quantity;
  final Money revenue;
}

/// Total taken via one payment method over the period.
class PaymentBreakdown {
  const PaymentBreakdown({
    required this.method,
    required this.amount,
    required this.count,
  });

  final String method; // cash | card | custom (or a custom label)
  final Money amount;
  final int count;
}

/// A computed sales report for a date window. [estimatedCost]/[estimatedProfit]
/// use the products' *current* cost price (POS lines don't capture cost at sale
/// time yet), so profit is an estimate until per-line cost is recorded.
class SalesReport {
  const SalesReport({
    required this.from,
    required this.to,
    required this.totalRevenue,
    required this.transactionCount,
    required this.estimatedCost,
    required this.topProducts,
    required this.paymentBreakdown,
  });

  final DateTime from;
  final DateTime to;
  final Money totalRevenue;
  final int transactionCount;
  final Money estimatedCost;
  final List<TopProduct> topProducts;
  final List<PaymentBreakdown> paymentBreakdown;

  Money get averageSale => transactionCount == 0
      ? Money.zero()
      : totalRevenue.divide(transactionCount).rounded();

  Money get estimatedProfit => totalRevenue.subtract(estimatedCost);

  bool get isEmpty => transactionCount == 0;
}
