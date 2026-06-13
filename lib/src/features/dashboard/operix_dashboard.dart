import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/database_config.dart';
import '../../domain/operix_models.dart';

class OperixDashboard extends StatelessWidget {
  const OperixDashboard({
    required this.selectedModule,
    required this.data,
    required this.databaseConfig,
    super.key,
  });

  final OperixModule selectedModule;
  final OperixDashboardData data;
  final DatabaseConfig databaseConfig;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: switch (selectedModule) {
          OperixModule.dashboard => _DashboardOverview(data: data),
          OperixModule.pointOfSale => _PosWorkspace(data: data),
          OperixModule.sales => _InvoiceWorkspace(
            title: 'Sales invoices',
            invoices: data.salesInvoices,
            emptyLabel: 'No sales invoices loaded',
          ),
          OperixModule.purchases => _InvoiceWorkspace(
            title: 'Purchase invoices',
            invoices: data.purchaseInvoices,
            emptyLabel: 'No purchase invoices loaded',
          ),
          OperixModule.inventory => _InventoryWorkspace(data: data),
          OperixModule.clients => _DirectoryWorkspace(
            title: 'Client accounts',
            records: data.clients,
          ),
          OperixModule.suppliers => _DirectoryWorkspace(
            title: 'Supplier accounts',
            records: data.suppliers,
          ),
          OperixModule.accounting => _AccountingWorkspace(data: data),
          OperixModule.settings => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({required this.data});

  final OperixDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(metrics: data.metrics),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Panel(
                title: 'Business modules',
                horizontalScroll: true,
                child: _ModuleTable(modules: data.modules),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: _ConnectionPanel(status: data.connectionStatus),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Panel(
                title: 'Recent activity',
                child: _ActivityList(entries: data.activities),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _Panel(
                title: 'Low stock watch',
                horizontalScroll: true,
                child: _InventoryTable(alerts: data.inventoryAlerts),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<OperixMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1180
            ? 4
            : constraints.maxWidth > 860
            ? 3
            : 2;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _MetricCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final OperixMetric metric;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(metric.tone);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey.shade500),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF17211F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              metric.label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D4A45),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF66756F), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTable extends StatelessWidget {
  const _ModuleTable({required this.modules});

  final List<OperixModuleSummary> modules;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Module')),
        DataColumn(label: Text('Records')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Owner')),
      ],
      rows: [
        for (final module in modules)
          DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 280,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        module.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF66756F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(module.primaryCount)),
              DataCell(_ChipLabel(label: module.status)),
              DataCell(Text(module.owner)),
            ],
          ),
      ],
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.status});

  final DatabaseConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.connected
        ? const Color(0xFF047857)
        : status.configured
        ? const Color(0xFFBE123C)
        : const Color(0xFFB45309);
    return _Panel(
      title: 'Data source',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.connected ? Icons.check_circle : Icons.info,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.target,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status.message,
            style: const TextStyle(color: Color(0xFF4E5E58), height: 1.35),
          ),
          const SizedBox(height: 16),
          _ChipLabel(
            label: status.connected ? 'Live database' : 'Seed data',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.entries});

  final List<ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    entry.time,
                    style: const TextStyle(
                      color: Color(0xFF66756F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF66756F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.amount,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InventoryWorkspace extends StatelessWidget {
  const _InventoryWorkspace({required this.data});

  final OperixDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _TwoColumn(
      left: _Panel(
        title: 'Low stock',
        horizontalScroll: true,
        child: _InventoryTable(alerts: data.inventoryAlerts),
      ),
      right: _Panel(
        title: 'Inventory controls',
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionRow(Icons.add_box_outlined, 'Create product'),
            _ActionRow(Icons.qr_code_2, 'Print barcode labels'),
            _ActionRow(Icons.compare_arrows, 'Transfer stock'),
            _ActionRow(Icons.fact_check_outlined, 'Start stock count'),
          ],
        ),
      ),
    );
  }
}

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({required this.alerts});

  final List<InventoryAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    return DataTable(
      columns: const [
        DataColumn(label: Text('SKU')),
        DataColumn(label: Text('Item')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Value')),
      ],
      rows: [
        for (final alert in alerts)
          DataRow(
            cells: [
              DataCell(Text(alert.sku)),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    alert.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text('${alert.quantity}/${alert.reorderLevel}')),
              DataCell(Text(currency.format(alert.quantity * alert.unitPrice))),
            ],
          ),
      ],
    );
  }
}

class _PosWorkspace extends StatelessWidget {
  const _PosWorkspace({required this.data});

  final OperixDashboardData data;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final total = data.posLines.fold<double>(
      0,
      (sum, line) => sum + line.total,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _Panel(
            title: 'Cashier sale',
            child: Column(
              children: [
                for (final line in data.posLines)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(line.name),
                    subtitle: Text('Qty ${line.quantity}'),
                    trailing: Text(
                      currency.format(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: _Panel(
            title: 'Payment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AmountRow(label: 'Subtotal', value: currency.format(total)),
                _AmountRow(label: 'VAT', value: currency.format(total * 0.14)),
                const Divider(height: 28),
                _AmountRow(
                  label: 'Total',
                  value: currency.format(total * 1.14),
                  strong: true,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print receipt'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Split payment'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceWorkspace extends StatelessWidget {
  const _InvoiceWorkspace({
    required this.title,
    required this.invoices,
    required this.emptyLabel,
  });

  final String title;
  final List<InvoicePreview> invoices;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      horizontalScroll: invoices.isNotEmpty,
      child: invoices.isEmpty
          ? Text(emptyLabel)
          : _InvoiceTable(invoices: invoices),
    );
  }
}

class _InvoiceTable extends StatelessWidget {
  const _InvoiceTable({required this.invoices});

  final List<InvoicePreview> invoices;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, yyyy');
    return DataTable(
      columns: const [
        DataColumn(label: Text('Number')),
        DataColumn(label: Text('Party')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Amount')),
      ],
      rows: [
        for (final invoice in invoices)
          DataRow(
            cells: [
              DataCell(Text(invoice.number)),
              DataCell(Text(invoice.party)),
              DataCell(Text(dateFormat.format(invoice.issueDate))),
              DataCell(_ChipLabel(label: invoice.status)),
              DataCell(Text(currency.format(invoice.amount))),
            ],
          ),
      ],
    );
  }
}

class _DirectoryWorkspace extends StatelessWidget {
  const _DirectoryWorkspace({required this.title, required this.records});

  final String title;
  final List<DirectoryRecord> records;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      horizontalScroll: true,
      child: _DirectoryTable(records: records),
    );
  }
}

class _DirectoryTable extends StatelessWidget {
  const _DirectoryTable({required this.records});

  final List<DirectoryRecord> records;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    return DataTable(
      columns: const [
        DataColumn(label: Text('Code')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Phone')),
        DataColumn(label: Text('Balance')),
        DataColumn(label: Text('Status')),
      ],
      rows: [
        for (final record in records)
          DataRow(
            cells: [
              DataCell(Text(record.code)),
              DataCell(Text(record.name)),
              DataCell(Text(record.phone)),
              DataCell(Text(currency.format(record.balance))),
              DataCell(_ChipLabel(label: record.status)),
            ],
          ),
      ],
    );
  }
}

class _AccountingWorkspace extends StatelessWidget {
  const _AccountingWorkspace({required this.data});

  final OperixDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _TwoColumn(
      left: _Panel(
        title: 'Accounting review',
        child: Column(
          children: [
            for (final task in data.accountingTasks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_alt),
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: _ChipLabel(label: task.status),
              ),
          ],
        ),
      ),
      right: _Panel(
        title: 'Reports',
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionRow(Icons.balance, 'Trial balance'),
            _ActionRow(Icons.account_tree_outlined, 'General ledger'),
            _ActionRow(Icons.query_stats, 'Profit and loss'),
            _ActionRow(Icons.receipt_long, 'Tax summary'),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.horizontalScroll = false,
  });

  final String title;
  final Widget child;
  final bool horizontalScroll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF182521),
              ),
            ),
            const SizedBox(height: 14),
            horizontalScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: child,
                  )
                : child,
          ],
        ),
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: left),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: right),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, this.color = const Color(0xFF0F766E)});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(54)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? const Color(0xFF182521)
                    : const Color(0xFF66756F),
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 20 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Color _toneColor(MetricTone tone) {
  switch (tone) {
    case MetricTone.teal:
      return const Color(0xFF0F766E);
    case MetricTone.amber:
      return const Color(0xFFB45309);
    case MetricTone.rose:
      return const Color(0xFFBE123C);
    case MetricTone.indigo:
      return const Color(0xFF4338CA);
    case MetricTone.emerald:
      return const Color(0xFF047857);
    case MetricTone.slate:
      return const Color(0xFF475569);
  }
}
