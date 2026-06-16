import '../domain/operix_models.dart';
import 'operix_repository.dart';

/// Empty dashboard data used when PostgreSQL is not configured, and as the
/// "no rows" fallback for [PostgresOperixRepository]. No sample data is seeded.
class DemoOperixRepository implements OperixRepository {
  @override
  Future<OperixDashboardData> loadDashboard({
    DashboardPeriod period = const DashboardPeriod.thisMonth(),
  }) async {
    // Demo data is empty regardless of the selected period.
    return OperixDashboardData(
      connectionStatus: await testConnection(),
      metrics: const [],
      modules: const [],
      activities: const [],
      inventoryAlerts: const [],
      salesInvoices: const [],
      purchaseInvoices: const [],
      posLines: const [],
      clients: const [],
      suppliers: const [],
      accountingTasks: const [],
      report: DashboardReport.demo(),
    );
  }

  @override
  Future<DatabaseConnectionStatus> testConnection() async {
    return DatabaseConnectionStatus(
      configured: false,
      connected: false,
      source: DataSourceMode.demo,
      target: 'Demo data',
      message: 'PostgreSQL is not configured; running with empty local data.',
      checkedAt: DateTime.now(),
    );
  }
}
