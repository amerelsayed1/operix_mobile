import 'package:postgres/postgres.dart';

import '../config/database_config.dart';
import '../domain/operix_models.dart';
import '../domain/value_objects/money.dart';
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
  Future<OperixDashboardData> loadDashboard({
    DashboardPeriod period = const DashboardPeriod.thisMonth(),
  }) async {
    final demoData = await fallback.loadDashboard(period: period);
    final window = period.resolve();

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
        report: await _loadReport(connection, demoData.report, window),
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
          unitPrice: _asMoney(map['unit_price']),
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
          amount: _asMoney(map['total_amount']),
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
          amount: _asMoney(map['total_amount']),
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
          price: _asMoney(map['unit_price']),
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
          balance: _asMoney(map['receivable_balance']),
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
          balance: _asMoney(map['payable_balance']).negate(),
          status: _titleCase(_asString(map['status'])),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  /// Computes the dashboard overview figures (KPIs, charts, top products)
  /// entirely from live data. Net sales use ex-tax subtotals; "expenses" is the
  /// total cost of sales (COGS + operating expenses) so that net profit, COGS
  /// and operating expenses sum back to revenue for the donut.
  Future<DashboardReport> _loadReport(
    Connection connection,
    DashboardReport fallback,
    DashboardPeriodWindow window,
  ) async {
    try {
      // Period-bounded flows (revenue, COGS, opex, orders, new customers and the
      // current/previous comparison) use the resolved [start, end) window and the
      // matching prior window. Point-in-time balances (cash, inventory value,
      // supplier dues) stay as live snapshots, independent of the period.
      final result = await connection.execute(
        Sql.named('''
        WITH
          pos_rev   AS (SELECT COALESCE(SUM(subtotal),0) v FROM pos_orders WHERE status='completed' AND created_at >= @start AND created_at < @end),
          inv_rev   AS (SELECT COALESCE(SUM(subtotal),0) v FROM sales_invoices WHERE status IN ('posted','paid') AND issue_date >= @start::date AND issue_date < @end::date),
          pos_cogs  AS (SELECT COALESCE(SUM(poi.quantity*COALESCE(NULLIF(poi.unit_cost,0),p.cost_price,0)),0) v
                          FROM pos_order_items poi
                          JOIN pos_orders po ON po.id=poi.pos_order_id AND po.status='completed' AND po.created_at >= @start AND po.created_at < @end
                          LEFT JOIN products p ON p.id=poi.product_id),
          inv_cogs  AS (SELECT COALESCE(SUM(sii.quantity*COALESCE(NULLIF(sii.unit_cost,0),p.cost_price,0)),0) v
                          FROM sales_invoice_items sii
                          JOIN sales_invoices si ON si.id=sii.sales_invoice_id AND si.status IN ('posted','paid') AND si.issue_date >= @start::date AND si.issue_date < @end::date
                          LEFT JOIN products p ON p.id=sii.product_id),
          opex      AS (SELECT COALESCE(SUM(CASE WHEN l.line_type='debit' THEN l.amount ELSE -l.amount END),0) v
                          FROM journal_entry_lines l
                          JOIN gl_accounts a ON a.id=l.gl_account_id
                          JOIN journal_entries j ON j.id=l.journal_entry_id AND j.status='posted' AND j.transaction_date >= @start::date AND j.transaction_date < @end::date
                         WHERE a.code='5200'),
          cash_pos  AS (SELECT COALESCE(SUM(amount),0) v FROM pos_order_payments),
          cash_inv  AS (SELECT COALESCE(SUM(total_amount),0) v FROM sales_invoices WHERE status='paid'),
          inv_val   AS (SELECT COALESCE(SUM(quantity_on_hand*cost_price),0) v FROM products),
          sup_due   AS (SELECT COALESCE(SUM(payable_balance),0) v FROM suppliers),
          ord_pos   AS (SELECT COUNT(*) v FROM pos_orders WHERE status='completed' AND created_at >= @start AND created_at < @end),
          ord_inv   AS (SELECT COUNT(*) v FROM sales_invoices WHERE status IN ('posted','paid') AND issue_date >= @start::date AND issue_date < @end::date),
          new_cust  AS (SELECT COUNT(*) v FROM clients WHERE created_at >= @start AND created_at < @end),
          cur       AS (SELECT
                          (SELECT COALESCE(SUM(subtotal),0) FROM pos_orders WHERE status='completed' AND created_at >= @start AND created_at < @end)
                        + (SELECT COALESCE(SUM(subtotal),0) FROM sales_invoices WHERE status IN ('posted','paid') AND issue_date >= @start::date AND issue_date < @end::date) v),
          prev      AS (SELECT
                          (SELECT COALESCE(SUM(subtotal),0) FROM pos_orders WHERE status='completed' AND created_at >= @prev_start AND created_at < @prev_end)
                        + (SELECT COALESCE(SUM(subtotal),0) FROM sales_invoices WHERE status IN ('posted','paid') AND issue_date >= @prev_start::date AND issue_date < @prev_end::date) v)
        SELECT pos_rev.v AS pos_rev, inv_rev.v AS inv_rev, pos_cogs.v AS pos_cogs,
               inv_cogs.v AS inv_cogs, opex.v AS opex, cash_pos.v AS cash_pos,
               cash_inv.v AS cash_inv, inv_val.v AS inv_val, sup_due.v AS sup_due,
               ord_pos.v AS ord_pos, ord_inv.v AS ord_inv, new_cust.v AS new_cust,
               cur.v AS cur, prev.v AS prev
        FROM pos_rev, inv_rev, pos_cogs, inv_cogs, opex, cash_pos, cash_inv,
             inv_val, sup_due, ord_pos, ord_inv, new_cust, cur, prev
      '''),
        parameters: {
          'start': window.start,
          'end': window.end,
          'prev_start': window.prevStart,
          'prev_end': window.prevEnd,
        },
      );

      if (result.isEmpty) {
        return fallback;
      }
      final map = result.first.toColumnMap();

      final revenue = _asMoney(map['pos_rev']).add(_asMoney(map['inv_rev']));
      final cogs = _asMoney(map['pos_cogs']).add(_asMoney(map['inv_cogs']));
      final opex = _asMoney(map['opex']);
      final expenses = cogs.add(opex);
      final netProfit = revenue.subtract(expenses);
      final cashBalance = _asMoney(
        map['cash_pos'],
      ).add(_asMoney(map['cash_inv']));
      final supplierDue = _asMoney(map['sup_due']).negate();
      final orderCount = _asInt(map['ord_pos']) + _asInt(map['ord_inv']);

      final revenueValue = revenue.toDouble();
      final grossMargin = revenueValue <= 0
          ? 0.0
          : (netProfit.toDouble() / revenueValue) * 100;
      final current = _asMoney(map['cur']).toDouble();
      final previous = _asMoney(map['prev']).toDouble();
      final revenueChangePct = previous > 0
          ? ((current - previous) / previous) * 100
          : (current > 0 ? 100.0 : 0.0);

      return DashboardReport(
        revenue: revenue.rounded(),
        expenses: expenses.rounded(),
        cogs: cogs.rounded(),
        netProfit: netProfit.rounded(),
        cashBalance: cashBalance.rounded(),
        inventoryValue: _asMoney(map['inv_val']).rounded(),
        supplierDue: supplierDue.rounded(),
        orderCount: orderCount,
        newCustomers: _asInt(map['new_cust']),
        grossMargin: grossMargin,
        revenueChangePct: revenueChangePct,
        salesTrend: await _loadSalesTrend(
          connection,
          fallback.salesTrend,
          window,
        ),
        topProducts: await _loadTopProducts(connection, fallback.topProducts),
        breakdown: RevenueBreakdown(
          netProfit: netProfit.rounded(),
          cogs: cogs.rounded(),
          operatingExpenses: opex.rounded(),
        ),
      );
    } catch (_) {
      return fallback;
    }
  }

  Future<List<SalesTrendPoint>> _loadSalesTrend(
    Connection connection,
    List<SalesTrendPoint> fallbackRows,
    DashboardPeriodWindow window,
  ) async {
    try {
      // One point per day across the selected window, capped at today so we
      // don't draw empty future days for month-to-date / custom ranges.
      final result = await connection.execute(
        Sql.named('''
        WITH days AS (
          SELECT generate_series(@start::date, LEAST(@end::date - 1, CURRENT_DATE), interval '1 day')::date AS d
        ),
        pos AS (
          SELECT created_at::date AS d, SUM(subtotal) AS amt
          FROM pos_orders
          WHERE status='completed' AND created_at >= @start AND created_at < @end
          GROUP BY 1
        ),
        inv AS (
          SELECT issue_date AS d, SUM(subtotal) AS amt
          FROM sales_invoices
          WHERE status IN ('posted','paid') AND issue_date >= @start::date AND issue_date < @end::date
          GROUP BY 1
        )
        SELECT days.d AS day, COALESCE(pos.amt,0) + COALESCE(inv.amt,0) AS net
        FROM days
        LEFT JOIN pos ON pos.d = days.d
        LEFT JOIN inv ON inv.d = days.d
        ORDER BY days.d
      '''),
        parameters: {'start': window.start, 'end': window.end},
      );

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return SalesTrendPoint(
          date: _asDate(map['day']),
          net: _asMoney(map['net']),
        );
      }).toList();

      return rows.isEmpty ? fallbackRows : rows;
    } catch (_) {
      return fallbackRows;
    }
  }

  Future<List<TopProduct>> _loadTopProducts(
    Connection connection,
    List<TopProduct> fallbackRows,
  ) async {
    try {
      final result = await connection.execute('''
        WITH lines AS (
          SELECT poi.name AS name, poi.quantity AS qty,
                 poi.quantity * poi.unit_price AS rev
          FROM pos_order_items poi
          JOIN pos_orders po ON po.id = poi.pos_order_id AND po.status='completed'
          UNION ALL
          SELECT sii.name AS name, sii.quantity AS qty, sii.line_total AS rev
          FROM sales_invoice_items sii
          JOIN sales_invoices si ON si.id = sii.sales_invoice_id
            AND si.status IN ('posted','paid')
        )
        SELECT name, SUM(rev) AS revenue, SUM(qty) AS quantity
        FROM lines
        GROUP BY name
        ORDER BY revenue DESC
        LIMIT 5
      ''');

      final rows = result.map((row) {
        final map = row.toColumnMap();
        return TopProduct(
          name: _asString(map['name']),
          revenue: _asMoney(map['revenue']),
          quantity: _asInt(map['quantity']),
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

  Money _asMoney(Object? value) => Money.parse(value);

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
