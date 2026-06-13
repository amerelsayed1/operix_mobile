import '../domain/operix_models.dart';

abstract interface class OperixRepository {
  Future<OperixDashboardData> loadDashboard();

  Future<DatabaseConnectionStatus> testConnection();
}
