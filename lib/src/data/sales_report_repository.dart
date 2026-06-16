import '../domain/report_models.dart';

/// Produces operational sales reports from the POS order tables.
abstract interface class SalesReportRepository {
  /// Builds a report for sales in `[from, to)` (to is exclusive).
  Future<SalesReport> generate({required DateTime from, required DateTime to});
}
