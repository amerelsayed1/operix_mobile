import 'value_objects/money.dart';

/// Dashboard reporting window options, mirroring the web dashboard's period
/// tabs: اليوم / آخر 7 أيام / هذا الشهر / مخصص.
enum PeriodType { today, last7Days, thisMonth, custom }

/// The selected dashboard reporting window. Drives which date range the KPIs,
/// charts and the period-over-period comparison are computed over. For
/// [PeriodType.custom], [from] and [to] are the inclusive day bounds chosen in
/// the date pickers.
class DashboardPeriod {
  const DashboardPeriod(this.type, {this.from, this.to});

  const DashboardPeriod.today()
    : type = PeriodType.today,
      from = null,
      to = null;
  const DashboardPeriod.last7Days()
    : type = PeriodType.last7Days,
      from = null,
      to = null;
  const DashboardPeriod.thisMonth()
    : type = PeriodType.thisMonth,
      from = null,
      to = null;
  const DashboardPeriod.custom(DateTime this.from, DateTime this.to)
    : type = PeriodType.custom;

  final PeriodType type;
  final DateTime? from;
  final DateTime? to;

  /// Resolves the concrete `[start, end)` window for this period plus the
  /// matching prior window (same length, immediately before it). All bounds are
  /// local-time and end-exclusive. Pass [clock] in tests for determinism.
  DashboardPeriodWindow resolve([DateTime? clock]) {
    final now = clock ?? DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (type) {
      case PeriodType.today:
        final end = startOfToday.add(const Duration(days: 1));
        return DashboardPeriodWindow(
          startOfToday,
          end,
          startOfToday.subtract(const Duration(days: 1)),
          startOfToday,
        );
      case PeriodType.last7Days:
        final start = startOfToday.subtract(const Duration(days: 6));
        final end = startOfToday.add(const Duration(days: 1));
        final length = end.difference(start);
        return DashboardPeriodWindow(start, end, start.subtract(length), start);
      case PeriodType.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        final prevStart = DateTime(now.year, now.month - 1, 1);
        return DashboardPeriodWindow(start, end, prevStart, start);
      case PeriodType.custom:
        final f = from ?? startOfToday;
        final t = to ?? startOfToday;
        final start = DateTime(f.year, f.month, f.day);
        final end = DateTime(
          t.year,
          t.month,
          t.day,
        ).add(const Duration(days: 1));
        final length = end.difference(start);
        return DashboardPeriodWindow(start, end, start.subtract(length), start);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardPeriod &&
      other.type == type &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(type, from, to);
}

/// Resolved, end-exclusive date bounds for a [DashboardPeriod] and its prior
/// comparison window.
class DashboardPeriodWindow {
  const DashboardPeriodWindow(
    this.start,
    this.end,
    this.prevStart,
    this.prevEnd,
  );

  final DateTime start;
  final DateTime end;
  final DateTime prevStart;
  final DateTime prevEnd;
}

enum OperixModule {
  dashboard,
  pointOfSale,
  sales,
  purchases,
  inventory,
  clients,
  suppliers,
  reports,
  accounting,
  users,
  settings,
}

enum DataSourceMode { demo, postgres }

class DatabaseConnectionStatus {
  const DatabaseConnectionStatus({
    required this.configured,
    required this.connected,
    required this.source,
    required this.target,
    required this.message,
    required this.checkedAt,
  });

  final bool configured;
  final bool connected;
  final DataSourceMode source;
  final String target;
  final String message;
  final DateTime checkedAt;
}

class OperixMetric {
  const OperixMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.tone,
  });

  final String label;
  final String value;
  final String detail;
  final MetricTone tone;
}

enum MetricTone { teal, amber, rose, indigo, emerald, slate }

class OperixModuleSummary {
  const OperixModuleSummary({
    required this.module,
    required this.title,
    required this.description,
    required this.primaryCount,
    required this.status,
    required this.owner,
  });

  final OperixModule module;
  final String title;
  final String description;
  final String primaryCount;
  final String status;
  final String owner;

  OperixModuleSummary copyWith({String? primaryCount, String? status}) {
    return OperixModuleSummary(
      module: module,
      title: title,
      description: description,
      primaryCount: primaryCount ?? this.primaryCount,
      status: status ?? this.status,
      owner: owner,
    );
  }
}

class ActivityEntry {
  const ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String time;
  final String amount;
}

class InventoryAlert {
  const InventoryAlert({
    required this.sku,
    required this.name,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.unitPrice,
  });

  final String sku;
  final String name;
  final String category;
  final int quantity;
  final int reorderLevel;
  final Money unitPrice;
}

class InvoicePreview {
  const InvoicePreview({
    required this.number,
    required this.party,
    required this.status,
    required this.issueDate,
    required this.amount,
  });

  final String number;
  final String party;
  final String status;
  final DateTime issueDate;
  final Money amount;
}

class PosLine {
  const PosLine({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final Money price;

  Money get total => price.multiply(quantity).rounded();
}

class DirectoryRecord {
  const DirectoryRecord({
    required this.name,
    required this.code,
    required this.phone,
    required this.balance,
    required this.status,
  });

  final String name;
  final String code;
  final String phone;
  final Money balance;
  final String status;
}

class AccountingTask {
  const AccountingTask({
    required this.title,
    required this.description,
    required this.status,
  });

  final String title;
  final String description;
  final String status;
}

/// A single day on the sales-trend line chart.
class SalesTrendPoint {
  const SalesTrendPoint({required this.date, required this.net});

  final DateTime date;
  final Money net;
}

/// A best-selling product, aggregated across POS sales and sales invoices.
class TopProduct {
  const TopProduct({
    required this.name,
    required this.revenue,
    required this.quantity,
  });

  final String name;
  final Money revenue;
  final int quantity;
}

/// The three slices of the revenue-distribution donut.
class RevenueBreakdown {
  const RevenueBreakdown({
    required this.netProfit,
    required this.cogs,
    required this.operatingExpenses,
  });

  factory RevenueBreakdown.empty() => RevenueBreakdown(
    netProfit: Money.zero(),
    cogs: Money.zero(),
    operatingExpenses: Money.zero(),
  );

  final Money netProfit;
  final Money cogs;
  final Money operatingExpenses;
}

/// Aggregated, ready-to-render figures for the dashboard overview. Computed by
/// the repository from live SQL (or zeroed via [DashboardReport.demo] when no
/// database is configured).
class DashboardReport {
  const DashboardReport({
    required this.revenue,
    required this.expenses,
    required this.cogs,
    required this.netProfit,
    required this.cashBalance,
    required this.inventoryValue,
    required this.supplierDue,
    required this.orderCount,
    required this.newCustomers,
    required this.grossMargin,
    required this.revenueChangePct,
    required this.salesTrend,
    required this.topProducts,
    required this.breakdown,
  });

  factory DashboardReport.demo() => DashboardReport(
    revenue: Money.zero(),
    expenses: Money.zero(),
    cogs: Money.zero(),
    netProfit: Money.zero(),
    cashBalance: Money.zero(),
    inventoryValue: Money.zero(),
    supplierDue: Money.zero(),
    orderCount: 0,
    newCustomers: 0,
    grossMargin: 0,
    revenueChangePct: 0,
    salesTrend: const [],
    topProducts: const [],
    breakdown: RevenueBreakdown.empty(),
  );

  final Money revenue;
  final Money expenses;
  final Money cogs;
  final Money netProfit;
  final Money cashBalance;
  final Money inventoryValue;
  final Money supplierDue;
  final int orderCount;
  final int newCustomers;
  final double grossMargin;
  final double revenueChangePct;
  final List<SalesTrendPoint> salesTrend;
  final List<TopProduct> topProducts;
  final RevenueBreakdown breakdown;

  Money get averageOrder =>
      orderCount == 0 ? Money.zero() : revenue.divide(orderCount).rounded();
}

class OperixDashboardData {
  const OperixDashboardData({
    required this.connectionStatus,
    required this.metrics,
    required this.modules,
    required this.activities,
    required this.inventoryAlerts,
    required this.salesInvoices,
    required this.purchaseInvoices,
    required this.posLines,
    required this.clients,
    required this.suppliers,
    required this.accountingTasks,
    required this.report,
  });

  final DatabaseConnectionStatus connectionStatus;
  final List<OperixMetric> metrics;
  final List<OperixModuleSummary> modules;
  final List<ActivityEntry> activities;
  final List<InventoryAlert> inventoryAlerts;
  final List<InvoicePreview> salesInvoices;
  final List<InvoicePreview> purchaseInvoices;
  final List<PosLine> posLines;
  final List<DirectoryRecord> clients;
  final List<DirectoryRecord> suppliers;
  final List<AccountingTask> accountingTasks;
  final DashboardReport report;

  OperixDashboardData copyWith({
    DatabaseConnectionStatus? connectionStatus,
    List<OperixMetric>? metrics,
    List<OperixModuleSummary>? modules,
    List<ActivityEntry>? activities,
    List<InventoryAlert>? inventoryAlerts,
    List<InvoicePreview>? salesInvoices,
    List<InvoicePreview>? purchaseInvoices,
    List<PosLine>? posLines,
    List<DirectoryRecord>? clients,
    List<DirectoryRecord>? suppliers,
    List<AccountingTask>? accountingTasks,
    DashboardReport? report,
  }) {
    return OperixDashboardData(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      metrics: metrics ?? this.metrics,
      modules: modules ?? this.modules,
      activities: activities ?? this.activities,
      inventoryAlerts: inventoryAlerts ?? this.inventoryAlerts,
      salesInvoices: salesInvoices ?? this.salesInvoices,
      purchaseInvoices: purchaseInvoices ?? this.purchaseInvoices,
      posLines: posLines ?? this.posLines,
      clients: clients ?? this.clients,
      suppliers: suppliers ?? this.suppliers,
      accountingTasks: accountingTasks ?? this.accountingTasks,
      report: report ?? this.report,
    );
  }
}
