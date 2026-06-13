import 'package:postgres/postgres.dart';

class DatabaseConfig {
  const DatabaseConfig({
    required this.connectionUrl,
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.sslModeName,
  });

  factory DatabaseConfig.fromEnvironment() {
    const connectionUrl = String.fromEnvironment('OPERIX_PG_URL');
    const host = String.fromEnvironment(
      'OPERIX_PG_HOST',
      defaultValue: 'localhost',
    );
    const port = int.fromEnvironment('OPERIX_PG_PORT', defaultValue: 5433);
    const database = String.fromEnvironment(
      'OPERIX_PG_DATABASE',
      defaultValue: 'operix',
    );
    const username = String.fromEnvironment(
      'OPERIX_PG_USER',
      defaultValue: 'operix',
    );
    const password = String.fromEnvironment(
      'OPERIX_PG_PASSWORD',
      defaultValue: 'operix_secret',
    );
    const sslModeName = String.fromEnvironment(
      'OPERIX_PG_SSL_MODE',
      defaultValue: 'disable',
    );

    return DatabaseConfig(
      connectionUrl: connectionUrl,
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
      sslModeName: sslModeName,
    );
  }

  final String connectionUrl;
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final String sslModeName;

  bool get isConfigured {
    return connectionUrl.trim().isNotEmpty ||
        (host.trim().isNotEmpty &&
            database.trim().isNotEmpty &&
            username.trim().isNotEmpty);
  }

  SslMode get sslMode {
    switch (sslModeName.trim().toLowerCase()) {
      case 'require':
        return SslMode.require;
      case 'verify-full':
      case 'verifyfull':
        return SslMode.verifyFull;
      case 'disable':
      default:
        return SslMode.disable;
    }
  }

  String get targetLabel {
    if (connectionUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(connectionUrl);
      if (uri != null && uri.host.isNotEmpty) {
        final resolvedPort = uri.hasPort ? uri.port : 5432;
        final databaseName = uri.pathSegments.isEmpty
            ? 'postgres'
            : uri.pathSegments.first;
        return '${uri.host}:$resolvedPort/$databaseName';
      }
      return 'PostgreSQL URL';
    }

    if (!isConfigured) {
      return 'Demo data';
    }

    return '$host:$port/$database';
  }
}
