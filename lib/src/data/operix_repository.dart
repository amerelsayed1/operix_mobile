import '../domain/operix_models.dart';

abstract interface class OperixRepository {
  /// Loads the dashboard for the given reporting [period]. Defaults to the
  /// current month to match the dashboard's default period tab (هذا الشهر).
  Future<OperixDashboardData> loadDashboard({
    DashboardPeriod period = const DashboardPeriod.thisMonth(),
  });

  Future<DatabaseConnectionStatus> testConnection();
}
