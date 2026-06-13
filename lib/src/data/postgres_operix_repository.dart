import 'package:postgres/postgres.dart';

import '../config/database_config.dart';
import '../domain/operix_models.dart';
import 'operix_repository.dart';

class PostgresOperixRepository implements OperixRepository {
  PostgresOperixRepository({required this.config, required this.fallback});

  final DatabaseConfig config;
  final OperixRepository fallback;

  static const _countTables = <String, OperixModule>{
    'clients': OperixModule.clients,
    'suppliers': OperixModule.suppliers,
    'products': OperixModule.inventory,
    'pos_orders': OperixModule.pointOfSale,
    'sales_invoices': OperixModule.sales,
    'supplier_invoices': OperixModule.purchases,
    'journal_entries': OperixModule.accounting,
  };

  @override
  Future<OperixDashboardData> loadDashboard() async {
    final demoData = await fallback.loadDashboard();

    if (!config.isConfigured) {
      return demoData.copyWith(connectionStatus: await testConnection());
    }

    Connection? connection;
    try {
      connection = await _open();
      final counts = <String, int?>{};
      for (final tableName in _countTables.keys) {
        counts[tableName] = await _safeCount(connection, tableName);
      }

      final status = DatabaseConnectionStatus(
        configured: true,
        connected: true,
        source: DataSourceMode.postgres,
        target: config.targetLabel,
        message: 'Connected to PostgreSQL and loaded available Operix tables.',
        checkedAt: DateTime.now(),
      );

      return demoData.copyWith(
        connectionStatus: status,
        metrics: _metricsFromCounts(counts),
        modules: _modulesFromCounts(demoData.modules, counts),
        inventoryAlerts: await _loadInventoryAlerts(
          connection,
          demoData.inventoryAlerts,
        ),
        salesInvoices: await _loadSalesInvoices(
          connection,
          demoData.salesInvoices,
        ),
        purchaseInvoices: await _loadSupplierInvoices(
          connection,
          demoData.purchaseInvoices,
        ),
        posLines: await _loadPosLines(connection, demoData.posLines),
        clients: await _loadClients(connection, demoData.clients),
        suppliers: await _loadSuppliers(connection, demoData.suppliers),
      );
    } catch (error) {
      return demoData.copyWith(
        connectionStatus: DatabaseConnectionStatus(
          configured: true,
          connected: false,
          source: DataSourceMode.demo,
          target: config.targetLabel,
          message: 'PostgreSQL connection failed: $error',
          checkedAt: DateTime.now(),
        ),
      );
    } finally {
      await connection?.close();
    }
  }

  @override
  Future<DatabaseConnectionStatus> testConnection() async {
    if (!config.isConfigured) {
      return DatabaseConnectionStatus(
        configured: false,
        connected: false,
        source: DataSourceMode.demo,
        target: config.targetLabel,
        message: 'PostgreSQL is not configured; using seeded desktop data.',
        checkedAt: DateTime.now(),
      );
    }

    Connection? connection;
    try {
      connection = await _open();
      await connection.execute('SELECT 1');
      return DatabaseConnectionStatus(
        configured: true,
        connected: true,
        source: DataSourceMode.postgres,
        target: config.targetLabel,
        message: 'PostgreSQL connection is healthy.',
        checkedAt: DateTime.now(),
      );
    } catch (error) {
      return DatabaseConnectionStatus(
        configured: true,
        connected: false,
        source: DataSourceMode.demo,
        target: config.targetLabel,
        message: 'PostgreSQL connection failed: $error',
        checkedAt: DateTime.now(),
      );
    } finally {
      await connection?.close();
    }
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

  Future<int?> _safeCount(Connection connection, String tableName) async {
    try {
      final result = await connection.execute(
        'SELECT COUNT(*)::int AS count FROM $tableName',
        timeout: const Duration(seconds: 4),
      );
      if (result.isEmpty) {
        return 0;
      }
      final count = result.first.toColumnMap()['count'];
      return count is int ? count : int.tryParse('$count');
    } catch (_) {
      return null;
    }
  }

  Future<List<InventoryAlert>> _loadInventoryAlerts(
    Connection connection,
    List<InventoryAlert> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        SELECT sku, name, category, quantity_on_hand, reorder_level, unit_price
        FROM products
        WHERE quantity_on_hand <= reorder_level
        ORDER BY quantity_on_hand ASC, name ASC
        LIMIT 8
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return InventoryAlert(
          sku: _asString(map['sku']),
          name: _asString(map['name']),
          category: _asString(map['category']),
          quantity: _asInt(map['quantity_on_hand']),
          reorderLevel: _asInt(map['reorder_level']),
          unitPrice: _asDouble(map['unit_price']),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  Future<List<InvoicePreview>> _loadSalesInvoices(
    Connection connection,
    List<InvoicePreview> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        SELECT
          si.invoice_number,
          COALESCE(c.name, 'Walk-in client') AS party,
          si.status,
          si.issue_date,
          si.total_amount
        FROM sales_invoices si
        LEFT JOIN clients c ON c.id = si.client_id
        ORDER BY si.issue_date DESC, si.id DESC
        LIMIT 8
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return InvoicePreview(
          number: _asString(map['invoice_number']),
          party: _asString(map['party']),
          status: _titleCase(_asString(map['status'])),
          issueDate: _asDate(map['issue_date']),
          amount: _asDouble(map['total_amount']),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  Future<List<InvoicePreview>> _loadSupplierInvoices(
    Connection connection,
    List<InvoicePreview> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        SELECT
          pi.invoice_number,
          COALESCE(s.company_name, 'Supplier') AS party,
          pi.status,
          pi.issue_date,
          pi.total_amount
        FROM supplier_invoices pi
        LEFT JOIN suppliers s ON s.id = pi.supplier_id
        ORDER BY pi.issue_date DESC, pi.id DESC
        LIMIT 8
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return InvoicePreview(
          number: _asString(map['invoice_number']),
          party: _asString(map['party']),
          status: _titleCase(_asString(map['status'])),
          issueDate: _asDate(map['issue_date']),
          amount: _asDouble(map['total_amount']),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  Future<List<PosLine>> _loadPosLines(
    Connection connection,
    List<PosLine> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        SELECT item.name, item.quantity, item.unit_price
        FROM pos_order_items item
        JOIN pos_orders po ON po.id = item.pos_order_id
        ORDER BY po.created_at DESC, item.id ASC
        LIMIT 8
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return PosLine(
          name: _asString(map['name']),
          quantity: _asInt(map['quantity']),
          price: _asDouble(map['unit_price']),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  Future<List<DirectoryRecord>> _loadClients(
    Connection connection,
    List<DirectoryRecord> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        SELECT client_code, name, phone, receivable_balance, status
        FROM clients
        ORDER BY created_at DESC, id DESC
        LIMIT 10
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return DirectoryRecord(
          name: _asString(map['name']),
          code: _asString(map['client_code']),
          phone: _asString(map['phone']),
          balance: _asDouble(map['receivable_balance']),
          status: _titleCase(_asString(map['status'])),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  Future<List<DirectoryRecord>> _loadSuppliers(
    Connection connection,
    List<DirectoryRecord> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        SELECT supplier_code, company_name, phone, payable_balance, status
        FROM suppliers
        ORDER BY created_at DESC, id DESC
        LIMIT 10
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return DirectoryRecord(
          name: _asString(map['company_name']),
          code: _asString(map['supplier_code']),
          phone: _asString(map['phone']),
          balance: -_asDouble(map['payable_balance']),
          status: _titleCase(_asString(map['status'])),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  List<OperixMetric> _metricsFromCounts(Map<String, int?> counts) {
    return [
      OperixMetric(
        label: 'Products',
        value: _countValue(counts['products']),
        detail: 'Inventory catalogue',
        tone: MetricTone.teal,
      ),
      OperixMetric(
        label: 'Clients',
        value: _countValue(counts['clients']),
        detail: 'Accounts receivable',
        tone: MetricTone.indigo,
      ),
      OperixMetric(
        label: 'Suppliers',
        value: _countValue(counts['suppliers']),
        detail: 'Accounts payable',
        tone: MetricTone.emerald,
      ),
      OperixMetric(
        label: 'POS orders',
        value: _countValue(counts['pos_orders']),
        detail: 'Point of sale records',
        tone: MetricTone.amber,
      ),
      OperixMetric(
        label: 'Sales invoices',
        value: _countValue(counts['sales_invoices']),
        detail: 'Formal invoice records',
        tone: MetricTone.rose,
      ),
      OperixMetric(
        label: 'Purchase invoices',
        value: _countValue(counts['supplier_invoices']),
        detail: 'Supplier invoice records',
        tone: MetricTone.slate,
      ),
      OperixMetric(
        label: 'Journal entries',
        value: _countValue(counts['journal_entries']),
        detail: 'Accounting postings',
        tone: MetricTone.amber,
      ),
    ];
  }

  List<OperixModuleSummary> _modulesFromCounts(
    List<OperixModuleSummary> fallbackModules,
    Map<String, int?> counts,
  ) {
    return fallbackModules.map((module) {
      final matchingTables = _countTables.entries
          .where((entry) => entry.value == module.module)
          .map((entry) => counts[entry.key])
          .whereType<int>()
          .toList();

      if (matchingTables.isEmpty) {
        return module.copyWith(status: 'Schema pending');
      }

      final total = matchingTables.fold<int>(0, (sum, value) => sum + value);
      return module.copyWith(
        primaryCount: '$total records',
        status: 'PostgreSQL',
      );
    }).toList();
  }

  String _countValue(int? value) {
    if (value == null) {
      return 'n/a';
    }
    return value.toString();
  }

  String _asString(Object? value) {
    return value?.toString() ?? '';
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _asDate(Object? value) {
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
