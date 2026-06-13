import 'package:postgres/postgres.dart';

import '../config/database_config.dart';

/// Owns a single lazily-opened PostgreSQL connection that is shared across the
/// repositories. The desktop client is single-user, so a shared connection that
/// is reused (and transparently reopened if it drops) is simpler and faster than
/// opening a fresh connection per query.
class OperixDatabase {
  OperixDatabase(this.config);

  final DatabaseConfig config;

  Connection? _connection;
  Future<Connection>? _opening;

  bool get isConfigured => config.isConfigured;

  /// Returns a live connection, opening one on first use.
  Future<Connection> connection() async {
    final existing = _connection;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    return _opening ??= _open()
        .then((conn) {
          _connection = conn;
          _opening = null;
          return conn;
        })
        .catchError((Object error) {
          _opening = null;
          throw error;
        });
  }

  Future<Connection> _open() {
    if (config.connectionUrl.trim().isNotEmpty) {
      return Connection.openFromUrl(config.connectionUrl);
    }

    return Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password.isEmpty ? null : config.password,
      ),
      settings: ConnectionSettings(
        applicationName: 'operix_flutter_desktop',
        sslMode: config.sslMode,
      ),
    );
  }

  Future<void> close() async {
    final conn = _connection;
    _connection = null;
    await conn?.close();
  }
}
