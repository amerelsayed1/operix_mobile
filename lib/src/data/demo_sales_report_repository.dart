import '../domain/report_models.dart';
import '../domain/value_objects/money.dart';
import 'sales_report_repository.dart';

/// Empty report used when PostgreSQL is not configured.
class DemoSalesReportRepository implements SalesReportRepository {
  @override
  Future<SalesReport> generate({
    required DateTime from,
    required DateTime to,
  }) async {
    return SalesReport(
      from: from,
      to: to,
      totalRevenue: Money.zero(),
      transactionCount: 0,
      estimatedCost: Money.zero(),
      topProducts: const [],
      paymentBreakdown: const [],
    );
  }
}
