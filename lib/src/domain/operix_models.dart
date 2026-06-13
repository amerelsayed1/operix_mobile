enum OperixModule {
  dashboard,
  pointOfSale,
  sales,
  purchases,
  inventory,
  clients,
  suppliers,
  accounting,
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
  final double unitPrice;
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
  final double amount;
}

class PosLine {
  const PosLine({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;

  double get total => quantity * price;
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
  final double balance;
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
    );
  }
}
