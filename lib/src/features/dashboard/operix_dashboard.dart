import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/l10n_ext.dart';
import '../../config/database_config.dart';
import '../../data/customer_repository.dart';
import '../../data/license_repository.dart';
import '../../data/product_repository.dart';
import '../../data/purchase_invoice_repository.dart';
import '../../data/sales_invoice_repository.dart';
import '../../data/supplier_repository.dart';
import '../../domain/customer_models.dart';
import '../../domain/inventory_models.dart';
import '../../domain/license_models.dart';
import '../../domain/operix_models.dart';
import '../../domain/purchase_invoice_models.dart';
import '../../domain/sales_invoice_models.dart';
import '../../domain/supplier_models.dart';
import '../../domain/value_objects/money.dart';

enum OperixSalesWorkspace { invoices, createInvoice, posOrders, returns }

enum OperixPurchaseWorkspace { invoices, createInvoice }

class OperixDashboard extends StatelessWidget {
  const OperixDashboard({
    required this.selectedModule,
    required this.data,
    required this.databaseConfig,
    required this.onModuleSelected,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.salesWorkspace,
    required this.onSalesWorkspaceSelected,
    required this.purchaseWorkspace,
    required this.onPurchaseWorkspaceSelected,
    super.key,
  });

  final OperixModule selectedModule;
  final OperixDashboardData data;
  final DatabaseConfig databaseConfig;
  final ValueChanged<OperixModule> onModuleSelected;
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final OperixSalesWorkspace salesWorkspace;
  final ValueChanged<OperixSalesWorkspace> onSalesWorkspaceSelected;
  final OperixPurchaseWorkspace purchaseWorkspace;
  final ValueChanged<OperixPurchaseWorkspace> onPurchaseWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: selectedModule == OperixModule.dashboard
            ? const EdgeInsets.fromLTRB(20, 18, 20, 28)
            : const EdgeInsets.all(24),
        child: switch (selectedModule) {
          OperixModule.dashboard => _DashboardOverview(
            data: data,
            onModuleSelected: onModuleSelected,
            selectedPeriod: selectedPeriod,
            onPeriodChanged: onPeriodChanged,
            onSalesWorkspaceSelected: onSalesWorkspaceSelected,
            onPurchaseWorkspaceSelected: onPurchaseWorkspaceSelected,
          ),
          OperixModule.pointOfSale => _PosWorkspace(data: data),
          OperixModule.sales => _SalesWorkspace(
            data: data,
            workspace: salesWorkspace,
            onWorkspaceSelected: onSalesWorkspaceSelected,
          ),
          OperixModule.purchases => _PurchaseWorkspace(
            data: data,
            workspace: purchaseWorkspace,
            onWorkspaceSelected: onPurchaseWorkspaceSelected,
          ),
          OperixModule.inventory => _InventoryWorkspace(data: data),
          OperixModule.clients => _DirectoryWorkspace(
            title: context.l10n.clientAccounts,
            records: data.clients,
          ),
          OperixModule.suppliers => _DirectoryWorkspace(
            title: context.l10n.supplierAccounts,
            records: data.suppliers,
          ),
          OperixModule.accounting => _AccountingWorkspace(data: data),
          OperixModule.reports => const SizedBox.shrink(),
          OperixModule.users => const SizedBox.shrink(),
          OperixModule.settings => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview({
    required this.data,
    required this.onModuleSelected,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onSalesWorkspaceSelected,
    required this.onPurchaseWorkspaceSelected,
  });

  final OperixDashboardData data;
  final ValueChanged<OperixModule> onModuleSelected;
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final ValueChanged<OperixSalesWorkspace> onSalesWorkspaceSelected;
  final ValueChanged<OperixPurchaseWorkspace> onPurchaseWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    final report = data.report;
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Text(
            l10n.dashOverviewTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: _PeriodTabs(
              selected: selectedPeriod,
              onChanged: onPeriodChanged,
            ),
          ),
          const SizedBox(height: 22),
          _LicenseExpiryBanner(
            onManage: () => onModuleSelected(OperixModule.settings),
          ),
          Text(
            l10n.dashQuickActions,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          _QuickActions(
            onModuleSelected: onModuleSelected,
            onSalesWorkspaceSelected: onSalesWorkspaceSelected,
            onPurchaseWorkspaceSelected: onPurchaseWorkspaceSelected,
          ),
          const SizedBox(height: 22),
          _DashboardMetricGrid(
            report: report,
            onModuleSelected: onModuleSelected,
          ),
          const SizedBox(height: 22),
          _DashboardCharts(report: report, onModuleSelected: onModuleSelected),
          const SizedBox(height: 22),
          _DashboardInsightGrid(
            report: report,
            onModuleSelected: onModuleSelected,
          ),
          const SizedBox(height: 22),
          _DashboardBottomRow(
            report: report,
            alerts: data.inventoryAlerts,
            onModuleSelected: onModuleSelected,
          ),
        ],
      ),
    );
  }
}

/// Builds a KPI subtitle from a period-over-period percentage change.
/// [vsPrevious] is the localized "vs previous period" phrase.
String _changeSubtitle(double pct, String vsPrevious) {
  final arrow = pct >= 0 ? '↗' : '↘';
  return '$arrow ${pct.abs().toStringAsFixed(1)}% $vsPrevious';
}

/// Formats a date following the active app locale (e.g. `June 14, 2026` in
/// English, `١٤ يونيو ٢٠٢٦` in Arabic).
String _formatLocaleDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(date);

const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Formats a date as `2026 يونيو 14` (year month day) to match the invoice UI.
String _formatArabicDate(DateTime date) =>
    '${date.year} ${_arabicMonths[date.month - 1]} ${date.day}';

class _PeriodTabs extends StatefulWidget {
  const _PeriodTabs({required this.selected, required this.onChanged});

  /// The currently active period (controlled by the shell).
  final DashboardPeriod selected;

  /// Called with the new period when the user picks a tab or a custom range.
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  State<_PeriodTabs> createState() => _PeriodTabsState();
}

class _PeriodTabsState extends State<_PeriodTabs> {
  static const _types = [
    PeriodType.today,
    PeriodType.last7Days,
    PeriodType.thisMonth,
    PeriodType.custom,
  ];

  // The custom date row stays open while the user configures a range, even
  // before both dates are chosen (so the مخصص tab feels selected immediately).
  late bool _customExpanded;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _customExpanded = widget.selected.type == PeriodType.custom;
    _from = widget.selected.from;
    _to = widget.selected.to;
  }

  int get _selectedIndex =>
      _customExpanded ? 3 : _types.indexOf(widget.selected.type);

  void _onTabTap(int index) {
    if (index == 3) {
      setState(() => _customExpanded = true);
      _maybeEmitCustom();
      return;
    }
    setState(() => _customExpanded = false);
    widget.onChanged(DashboardPeriod(_types[index]));
  }

  void _maybeEmitCustom() {
    if (_from != null && _to != null) {
      widget.onChanged(DashboardPeriod.custom(_from!, _to!));
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null && _to!.isBefore(picked)) _to = picked;
      } else {
        _to = picked;
        if (_from != null && _from!.isAfter(picked)) _from = picked;
      }
    });
    _maybeEmitCustom();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;
    final l10n = context.l10n;
    final labels = [
      l10n.dashPeriodToday,
      l10n.dashPeriodLast7,
      l10n.dashPeriodThisMonth,
      l10n.dashPeriodCustom,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: _PeriodTab(
                    label: labels[i],
                    selected: i == selectedIndex,
                    onTap: () => _onTabTap(i),
                  ),
                ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _customExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CustomDateField(
                  label: l10n.dashFrom,
                  value: _from,
                  onTap: () => _pickDate(isFrom: true),
                ),
                const SizedBox(width: 12),
                _CustomDateField(
                  label: l10n.dashTo,
                  value: _to,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A تاريخ (date) input used by the custom period range. Tapping opens a date
/// picker; shows the chosen date formatted in Arabic.
class _CustomDateField extends StatelessWidget {
  const _CustomDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                value == null
                    ? context.l10n.dashPickDate
                    : _formatLocaleDate(context, value!),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5B63F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashboard banner that warns when the active Operix license is close to
/// expiry. Hidden entirely while the license has more than [_warnWithinDays]
/// left (or when no valid license is loaded — expired/missing licenses are
/// already blocked upstream by the license gate, so they never reach here).
class _LicenseExpiryBanner extends StatefulWidget {
  const _LicenseExpiryBanner({required this.onManage});

  /// Invoked when the user taps "إدارة الترخيص" (opens Settings, where the
  /// license card lives).
  final VoidCallback onManage;

  /// Start warning this many days before expiry.
  static const int _warnWithinDays = 30;

  /// Escalate to the urgent (red) style at or below this many days.
  static const int _urgentWithinDays = 7;

  @override
  State<_LicenseExpiryBanner> createState() => _LicenseExpiryBannerState();
}

class _LicenseExpiryBannerState extends State<_LicenseExpiryBanner> {
  late final Future<LicenseValidationResult> _future;

  @override
  void initState() {
    super.initState();
    // Read once; the license file is small and rarely changes within a session.
    _future = context.read<LicenseRepository>().loadLicense();
  }

  /// Shows the Operix sales contact so the user can renew/upgrade. Kept
  /// dependency-free (no url_launcher): displays the address with a copy action.
  Future<void> _contactSales() async {
    const salesEmail = 'sales@operixhq.com';
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dashContactSales),
        content: Text(l10n.dashContactSalesBody),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: salesEmail));
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.dashSalesEmailCopied)),
              );
            },
            child: Text(l10n.dashCopyEmail),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.dashOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseValidationResult>(
      future: _future,
      builder: (context, snapshot) {
        final result = snapshot.data;
        final license = result?.license;
        // Only warn for a genuinely valid license that's nearing expiry.
        if (license == null ||
            result?.status != LicenseStatus.valid ||
            license.daysRemaining > _LicenseExpiryBanner._warnWithinDays) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final days = license.daysRemaining;
        final urgent = days <= _LicenseExpiryBanner._urgentWithinDays;
        final background = urgent
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFFFF7ED);
        final border = urgent
            ? const Color(0xFFFECACA)
            : const Color(0xFFFED7AA);
        final accent = urgent
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);
        final titleColor = urgent
            ? const Color(0xFF991B1B)
            : const Color(0xFF9A3412);
        final bodyColor = urgent
            ? const Color(0xFFB91C1C)
            : const Color(0xFFB45309);

        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashLicenseExpiryAlert,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.dashLicenseExpiryHeadline(
                          days,
                          license.businessName,
                        ),
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashLicenseExpiryFooter(
                          _formatLocaleDate(
                            context,
                            license.expiresAt.toLocal(),
                          ),
                        ),
                        style: TextStyle(
                          color: bodyColor,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: _contactSales,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(l10n.dashContactSales),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: widget.onManage,
                      style: TextButton.styleFrom(foregroundColor: accent),
                      child: Text(l10n.dashManageLicense),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onModuleSelected,
    required this.onSalesWorkspaceSelected,
    required this.onPurchaseWorkspaceSelected,
  });

  final ValueChanged<OperixModule> onModuleSelected;
  final ValueChanged<OperixSalesWorkspace> onSalesWorkspaceSelected;
  final ValueChanged<OperixPurchaseWorkspace> onPurchaseWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      _QuickDashboardAction(
        Icons.note_add_outlined,
        l10n.dashActionNewSalesInvoice,
        OperixModule.sales,
        salesWorkspace: OperixSalesWorkspace.createInvoice,
      ),
      _QuickDashboardAction(
        Icons.shopping_cart_outlined,
        l10n.titlePointOfSale,
        OperixModule.pointOfSale,
      ),
      _QuickDashboardAction(
        Icons.attach_money,
        l10n.dashActionNewExpense,
        OperixModule.accounting,
      ),
      _QuickDashboardAction(
        Icons.description_outlined,
        l10n.dashActionPurchaseInvoice,
        OperixModule.purchases,
        purchaseWorkspace: OperixPurchaseWorkspace.createInvoice,
      ),
      _QuickDashboardAction(
        Icons.local_shipping_outlined,
        l10n.newSupplier,
        OperixModule.suppliers,
      ),
      _QuickDashboardAction(
        Icons.inventory_2_outlined,
        l10n.newProduct,
        OperixModule.inventory,
      ),
      _QuickDashboardAction(
        Icons.refresh,
        l10n.dashActionSalesReturns,
        OperixModule.sales,
        salesWorkspace: OperixSalesWorkspace.returns,
      ),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final action in actions)
          _QuickActionChip(
            icon: action.icon,
            label: action.label,
            onPressed: () {
              final salesWorkspace = action.salesWorkspace;
              if (salesWorkspace != null) {
                onSalesWorkspaceSelected(salesWorkspace);
              } else if (action.purchaseWorkspace != null) {
                onPurchaseWorkspaceSelected(action.purchaseWorkspace!);
              } else {
                onModuleSelected(action.module);
              }
            },
          ),
      ],
    );
  }
}

class _QuickDashboardAction {
  const _QuickDashboardAction(
    this.icon,
    this.label,
    this.module, {
    this.salesWorkspace,
    this.purchaseWorkspace,
  });

  final IconData icon;
  final String label;
  final OperixModule module;
  final OperixSalesWorkspace? salesWorkspace;
  final OperixPurchaseWorkspace? purchaseWorkspace;
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _DashboardMetricGrid extends StatelessWidget {
  const _DashboardMetricGrid({
    required this.report,
    required this.onModuleSelected,
  });

  final DashboardReport report;
  final ValueChanged<OperixModule> onModuleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = l10n.currencyEgp;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 980
            ? 4
            : constraints.maxWidth > 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: width,
              child: _DashboardKpiCard(
                title: l10n.dashKpiRevenue,
                value: _formatEgp(report.revenue, unit: unit),
                subtitle: _changeSubtitle(
                  report.revenueChangePct,
                  l10n.dashVsPreviousPeriod,
                ),
                icon: Icons.trending_up,
                tone: const Color(0xFF10B981),
                onPressed: () => onModuleSelected(OperixModule.reports),
              ),
            ),
            SizedBox(
              width: width,
              child: _DashboardKpiCard(
                title: l10n.dashKpiExpenses,
                value: _formatEgp(report.expenses, unit: unit),
                subtitle: l10n.dashKpiExpensesSubtitle,
                icon: Icons.credit_card,
                tone: const Color(0xFFEF4444),
                onPressed: () => onModuleSelected(OperixModule.accounting),
              ),
            ),
            SizedBox(
              width: width,
              child: _DashboardKpiCard(
                title: l10n.dashKpiNetProfit,
                value: _formatEgp(report.netProfit, unit: unit),
                subtitle: l10n.dashKpiNetProfitSubtitle,
                icon: Icons.trending_up,
                tone: const Color(0xFF22C55E),
                onPressed: () => onModuleSelected(OperixModule.reports),
              ),
            ),
            SizedBox(
              width: width,
              child: _DashboardKpiCard(
                title: l10n.dashKpiCashBalance,
                value: _formatEgp(report.cashBalance, unit: unit),
                subtitle: l10n.dashKpiCashBalanceSubtitle,
                icon: Icons.attach_money,
                tone: const Color(0xFF3B82F6),
                onPressed: () => onModuleSelected(OperixModule.accounting),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardKpiCard extends StatelessWidget {
  const _DashboardKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onPressed,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      minHeight: 148,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tone.withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: tone, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtitle.startsWith('↗')
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCharts extends StatelessWidget {
  const _DashboardCharts({
    required this.report,
    required this.onModuleSelected,
  });

  final DashboardReport report;
  final ValueChanged<OperixModule> onModuleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 860;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 320, child: _salesChart(l10n)),
              const SizedBox(height: 14),
              SizedBox(height: 320, child: _donutChart(l10n)),
            ],
          );
        }
        return SizedBox(
          height: 320,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _salesChart(l10n)),
              const SizedBox(width: 14),
              Expanded(child: _donutChart(l10n)),
            ],
          ),
        );
      },
    );
  }

  Widget _salesChart(AppLocalizations l10n) {
    return _DashboardCard(
      minHeight: 320,
      onPressed: () => onModuleSelected(OperixModule.reports),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: l10n.dashSalesTrend,
            subtitle: l10n.dashSalesTrendSubtitle,
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _SalesTrendChart(
              points: report.salesTrend,
              unit: l10n.currencyEgp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _donutChart(AppLocalizations l10n) {
    return _DashboardCard(
      minHeight: 320,
      onPressed: () => onModuleSelected(OperixModule.reports),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: l10n.dashRevenueDistribution,
            subtitle: l10n.dashRevenueDistributionSubtitle,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _RevenueDonutChart(breakdown: report.breakdown, l10n: l10n),
          ),
        ],
      ),
    );
  }
}

class _DashboardInsightGrid extends StatelessWidget {
  const _DashboardInsightGrid({
    required this.report,
    required this.onModuleSelected,
  });

  final DashboardReport report;
  final ValueChanged<OperixModule> onModuleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unit = l10n.currencyEgp;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 980
            ? 6
            : constraints.maxWidth > 720
            ? 3
            : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        final tiles = [
          _MiniMetricTile(
            title: l10n.dashTotalProfit,
            value: _formatEgp(report.netProfit, unit: unit),
            subtitle: l10n.dashMarginLabel(
              report.grossMargin.toStringAsFixed(1),
            ),
            icon: Icons.trending_up,
            tone: const Color(0xFF10B981),
            onPressed: () => onModuleSelected(OperixModule.reports),
          ),
          _MiniMetricTile(
            title: l10n.dashGrossMargin,
            value: '${report.grossMargin.toStringAsFixed(1)}%',
            subtitle: '—',
            icon: Icons.trending_up,
            tone: const Color(0xFF22C55E),
            onPressed: () => onModuleSelected(OperixModule.reports),
          ),
          _MiniMetricTile(
            title: l10n.dashInventoryValue,
            value: _formatEgp(report.inventoryValue, unit: unit),
            subtitle: l10n.dashAtCost,
            icon: Icons.inventory_2_outlined,
            tone: const Color(0xFF8B5CF6),
            onPressed: () => onModuleSelected(OperixModule.inventory),
          ),
          _MiniMetricTile(
            title: l10n.dashOrders,
            value: '${report.orderCount}',
            subtitle: l10n.dashAverageLabel(
              _formatEgp(report.averageOrder, unit: unit),
            ),
            icon: Icons.shopping_cart_outlined,
            tone: const Color(0xFFF59E0B),
            onPressed: () => onModuleSelected(OperixModule.sales),
          ),
          _MiniMetricTile(
            title: l10n.dashNewCustomers,
            value: '${report.newCustomers}',
            subtitle: l10n.dashThisPeriod,
            icon: Icons.group_add_outlined,
            tone: const Color(0xFF60A5FA),
            onPressed: () => onModuleSelected(OperixModule.clients),
          ),
          _MiniMetricTile(
            title: l10n.dashSupplierDue,
            value: _formatEgp(report.supplierDue, unit: unit),
            subtitle: l10n.dashTotalDueAmount,
            icon: Icons.local_shipping_outlined,
            tone: const Color(0xFFEF4444),
            danger: true,
            onPressed: () => onModuleSelected(OperixModule.suppliers),
          ),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  const _MiniMetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onPressed,
    this.danger = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      minHeight: 116,
      padding: const EdgeInsets.all(16),
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tone.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: tone, size: 17),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: danger ? const Color(0xFFDC2626) : const Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBottomRow extends StatelessWidget {
  const _DashboardBottomRow({
    required this.report,
    required this.alerts,
    required this.onModuleSelected,
  });

  final DashboardReport report;
  final List<InventoryAlert> alerts;
  final ValueChanged<OperixModule> onModuleSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopProductsCard(
                products: report.topProducts,
                onPressed: () => onModuleSelected(OperixModule.reports),
              ),
              const SizedBox(height: 14),
              _InventoryHealthCard(
                alerts: alerts,
                onPressed: () => onModuleSelected(OperixModule.inventory),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _TopProductsCard(
                products: report.topProducts,
                onPressed: () => onModuleSelected(OperixModule.reports),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _InventoryHealthCard(
                alerts: alerts,
                onPressed: () => onModuleSelected(OperixModule.inventory),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InventoryHealthCard extends StatelessWidget {
  const _InventoryHealthCard({required this.alerts, required this.onPressed});

  final List<InventoryAlert> alerts;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final lowCount = alerts.length;
    final healthy = lowCount == 0;
    final background = healthy
        ? const Color(0xFFECFDF3)
        : const Color(0xFFFEF2F2);
    final border = healthy ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA);
    final iconBg = healthy ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
    final iconColor = healthy
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final titleColor = healthy
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);
    final bodyColor = healthy
        ? const Color(0xFF15803D)
        : const Color(0xFFB91C1C);
    final l10n = context.l10n;
    final title = healthy
        ? l10n.dashInventoryHealthy
        : l10n.dashInventoryLowCount(lowCount);
    final body = healthy
        ? l10n.dashInventoryHealthyBody
        : l10n.dashInventoryLowBody;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg.withAlpha(90),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  healthy
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      style: TextStyle(
                        color: bodyColor,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products, required this.onPressed});

  final List<TopProduct> products;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxRevenue = products.isEmpty
        ? 0.0
        : products
              .map((p) => p.revenue.toDouble())
              .reduce((a, b) => a > b ? a : b);
    return _DashboardCard(
      minHeight: 220,
      fixedHeight: false,
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(title: l10n.dashTopProducts, icon: Icons.trending_up),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                l10n.noSalesYet,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (var i = 0; i < products.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _TopProductBar(
                label: products[i].name,
                value: products[i].revenue,
                quantity: l10n.dashPiecesLabel(products[i].quantity),
                progress: maxRevenue <= 0
                    ? 0
                    : products[i].revenue.toDouble() / maxRevenue,
              ),
            ],
        ],
      ),
    );
  }
}

class _TopProductBar extends StatelessWidget {
  const _TopProductBar({
    required this.label,
    required this.value,
    required this.quantity,
    required this.progress,
  });

  final String label;
  final Money value;
  final String quantity;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              _formatEgp(value, unit: context.l10n.currencyEgp),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: const Color(0xFF22C55E),
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          quantity,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.minHeight,
    this.padding = const EdgeInsets.all(20),
    this.onPressed,
    this.fixedHeight = true,
  });

  final Widget child;
  final double? minHeight;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;

  /// When true (the default) [minHeight] pins the card to an exact height — this
  /// is required for cards whose content uses [Spacer], which needs a bounded
  /// height. Set to false for cards with a variable number of rows so they grow
  /// instead of overflowing.
  final bool fixedHeight;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final content = Container(
      constraints: minHeight == null
          ? const BoxConstraints()
          : fixedHeight
          ? BoxConstraints.tightFor(height: minHeight)
          : BoxConstraints(minHeight: minHeight!),
      padding: padding,
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: onPressed == null
            ? content
            : InkWell(
                onTap: onPressed,
                mouseCursor: SystemMouseCursors.click,
                child: content,
              ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF22C55E), size: 18),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueDonutChart extends StatefulWidget {
  const _RevenueDonutChart({required this.breakdown, required this.l10n});

  final RevenueBreakdown breakdown;
  final AppLocalizations l10n;

  @override
  State<_RevenueDonutChart> createState() => _RevenueDonutChartState();
}

class _RevenueDonutChartState extends State<_RevenueDonutChart> {
  Offset? _hover;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: MouseRegion(
                onHover: (e) => setState(() => _hover = e.localPosition),
                onExit: (_) => setState(() => _hover = null),
                child: CustomPaint(
                  painter: _DonutPainter(widget.breakdown, l10n, hover: _hover),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 8,
          children: [
            _LegendItem(
              color: const Color(0xFF10B981),
              label: l10n.dashKpiNetProfit,
            ),
            _LegendItem(color: const Color(0xFF8B5CF6), label: l10n.dashCogs),
            _LegendItem(
              color: const Color(0xFFEF4444),
              label: l10n.dashKpiExpenses,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.breakdown, this.l10n, {this.hover});

  final RevenueBreakdown breakdown;

  /// Localized strings for the slice labels and currency tooltip.
  final AppLocalizations l10n;

  /// Cursor position (local to the chart) used to show a slice tooltip.
  final Offset? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.shortestSide * 0.16;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Slices are clamped at zero so a loss (negative profit) doesn't draw a
    // backwards arc; the ring then just shows costs.
    final segments = <(String, double, Color)>[
      (
        l10n.dashKpiNetProfit,
        breakdown.netProfit.toDouble().clamp(0, double.infinity),
        const Color(0xFF10B981),
      ),
      (
        l10n.dashCogs,
        breakdown.cogs.toDouble().clamp(0, double.infinity),
        const Color(0xFF8B5CF6),
      ),
      (
        l10n.dashKpiExpenses,
        breakdown.operatingExpenses.toDouble().clamp(0, double.infinity),
        const Color(0xFFEF4444),
      ),
    ];
    final total = segments.fold<double>(0, (sum, v) => sum + v.$2);

    if (total <= 0) {
      paint.color = const Color(0xFFE5E7EB);
      canvas.drawArc(rect.deflate(stroke / 2), 0, 6.28318, false, paint);
      return;
    }

    const gap = 0.03;
    final drawn = segments.where((v) => v.$2 > 0).toList();
    // Full (gap-free) angular ranges per slice, used for hover hit-testing.
    final ranges = <(String, double, Color, double, double)>[];
    var start = -math.pi / 2;
    var hitStart = -math.pi / 2;
    for (final segment in drawn) {
      final fraction = segment.$2 / total;
      // Only inset by the gap when there's more than one visible slice.
      final sweep = (fraction * 6.28318) - (drawn.length > 1 ? gap : 0);
      paint.color = segment.$3;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep + (drawn.length > 1 ? gap : 0);
      final hitEnd = hitStart + fraction * 2 * math.pi;
      ranges.add((segment.$1, segment.$2, segment.$3, hitStart, hitEnd));
      hitStart = hitEnd;
    }

    // Hover tooltip: resolve which slice the cursor sits over.
    if (hover != null) {
      final center = size.center(Offset.zero);
      final rOuter = size.shortestSide / 2;
      final rInner = rOuter - stroke;
      final v = hover! - center;
      final dist = v.distance;
      if (dist >= rInner && dist <= rOuter) {
        var angle = math.atan2(v.dy, v.dx);
        while (angle < -math.pi / 2) {
          angle += 2 * math.pi;
        }
        for (final r in ranges) {
          if (angle >= r.$4 && angle < r.$5) {
            final pct = total <= 0 ? 0.0 : (r.$2 / total) * 100;
            _paintChartTooltip(canvas, hover!, [
              r.$1,
              '${_formatEgp(Money.fromNum(r.$2), unit: l10n.currencyEgp)} • ${pct.toStringAsFixed(1)}%',
            ], size);
            break;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.breakdown != breakdown ||
      oldDelegate.hover != hover ||
      oldDelegate.l10n != l10n;
}

class _SalesTrendChart extends StatefulWidget {
  const _SalesTrendChart({required this.points, required this.unit});

  final List<SalesTrendPoint> points;

  /// Localized currency unit used by the hover tooltip.
  final String unit;

  @override
  State<_SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<_SalesTrendChart> {
  Offset? _hover;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Center(
        child: Text(
          context.l10n.dashNoSalesData,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return MouseRegion(
      onHover: (e) => setState(() => _hover = e.localPosition),
      onExit: (_) => setState(() => _hover = null),
      child: CustomPaint(
        painter: _SalesTrendPainter(widget.points, widget.unit, hover: _hover),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws a small dark tooltip box near [anchor] with [lines] of text, clamped to
/// stay inside [bounds]. Shared by the sales-trend and donut charts.
void _paintChartTooltip(
  Canvas canvas,
  Offset anchor,
  List<String> lines,
  Size bounds,
) {
  const pad = 8.0;
  final painters = <TextPainter>[];
  var w = 0.0;
  var h = 0.0;
  for (var i = 0; i < lines.length; i++) {
    final tp = TextPainter(
      text: TextSpan(
        text: lines[i],
        style: TextStyle(
          color: Colors.white,
          fontSize: i == 0 ? 12 : 11,
          fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    painters.add(tp);
    if (tp.width > w) w = tp.width;
    h += tp.height + (i > 0 ? 2 : 0);
  }
  final boxW = w + pad * 2;
  final boxH = h + pad * 2;
  var dx = anchor.dx + 12;
  var dy = anchor.dy - boxH - 12;
  if (dx + boxW > bounds.width) dx = anchor.dx - boxW - 12;
  if (dx < 0) dx = 4;
  if (dy < 0) dy = anchor.dy + 12;
  final boxRect = Rect.fromLTWH(dx, dy, boxW, boxH);
  canvas.drawRRect(
    RRect.fromRectAndRadius(boxRect, const Radius.circular(8)),
    Paint()..color = const Color(0xFF0F172A).withAlpha(235),
  );
  var cy = dy + pad;
  for (final tp in painters) {
    tp.paint(canvas, Offset(dx + boxW - pad - tp.width, cy));
    cy += tp.height + 2;
  }
}

class _SalesTrendPainter extends CustomPainter {
  _SalesTrendPainter(this.points, this.unit, {this.hover});

  final List<SalesTrendPoint> points;

  /// Localized currency unit used by the hover tooltip.
  final String unit;

  /// Cursor position (local to the chart) used to show a point tooltip.
  final Offset? hover;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 48.0;
    const right = 10.0;
    const top = 14.0;
    const bottom = 34.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    const labelStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    final values = points.map((p) => p.net.toDouble()).toList();
    var hi = values.reduce((a, b) => a > b ? a : b);
    var lo = values.reduce((a, b) => a < b ? a : b);
    if (hi < 0) hi = 0;
    if (lo > 0) lo = 0;
    if (hi == lo) hi = lo + 1; // avoid a zero range when everything is flat.
    final range = hi - lo;

    double yFor(double v) => chart.bottom - ((v - lo) / range) * chart.height;

    const divisions = 4;
    for (var i = 0; i <= divisions; i++) {
      final value = hi - (range / divisions) * i;
      final y = yFor(value);
      _drawDashedLine(
        canvas,
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
      _paintText(canvas, _compact(value), Offset(0, y - 6), labelStyle);
    }

    final zeroY = yFor(0);
    if (lo < 0) {
      canvas.drawLine(
        Offset(chart.left, zeroY),
        Offset(chart.right, zeroY),
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..strokeWidth = 1.2,
      );
    }

    final pts = <Offset>[];
    final divisor = points.length == 1 ? 1 : points.length - 1;
    for (var i = 0; i < points.length; i++) {
      final x = chart.left + (chart.width / divisor) * i;
      pts.add(Offset(x, yFor(values[i])));
    }

    final area = Path()..moveTo(pts.first.dx, zeroY);
    for (final point in pts) {
      area.lineTo(point.dx, point.dy);
    }
    area.lineTo(pts.last.dx, zeroY);
    area.close();
    canvas.drawPath(
      area,
      Paint()..color = const Color(0xFF6366F1).withAlpha(20),
    );

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final previous = pts[i - 1];
      final current = pts[i];
      final midX = (previous.dx + current.dx) / 2;
      line.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 2.3
        ..style = PaintingStyle.stroke,
    );
    final dotPaint = Paint()..color = const Color(0xFF6366F1);
    for (final point in pts) {
      canvas.drawCircle(point, 3, dotPaint);
    }

    // Show about 7 evenly-spaced date labels so they don't overlap.
    final formatter = DateFormat('MMM d');
    final step = (points.length / 7).ceil().clamp(1, points.length);
    for (var i = 0; i < points.length; i += step) {
      final x = chart.left + (chart.width / divisor) * i;
      _paintText(
        canvas,
        formatter.format(points[i].date),
        Offset(x - 18, chart.bottom + 14),
        labelStyle,
      );
    }

    // Hover tooltip: highlight the nearest point (by x) and show its date+value.
    if (hover != null && pts.isNotEmpty) {
      var nearest = 0;
      var bestDx = double.infinity;
      for (var i = 0; i < pts.length; i++) {
        final dx = (pts[i].dx - hover!.dx).abs();
        if (dx < bestDx) {
          bestDx = dx;
          nearest = i;
        }
      }
      final p = pts[nearest];
      canvas.drawLine(
        Offset(p.dx, chart.top),
        Offset(p.dx, chart.bottom),
        Paint()
          ..color = const Color(0xFF6366F1).withAlpha(70)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = const Color(0xFF6366F1));
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
      final tipFormatter = DateFormat('MMM d');
      _paintChartTooltip(canvas, p, [
        tipFormatter.format(points[nearest].date),
        _formatEgp(points[nearest].net, unit: unit),
      ], size);
    }
  }

  String _compact(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000) {
      return '$sign${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
    }
    return '$sign${abs.toStringAsFixed(0)}';
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 5.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset((x + dash).clamp(x, end.dx), end.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.hover != hover ||
      oldDelegate.unit != unit;
}

/// Formats money with a trailing currency [unit]. The default keeps the Arabic
/// `ج.م` suffix used by the (still RTL) sales/purchase screens; the localized
/// dashboard passes `context.l10n.currencyEgp` so it follows the app locale.
String _formatEgp(Money amount, {String unit = 'ج.م'}) {
  final value = amount.rounded();
  final prefix = value.isNegative ? '-' : '';
  final formatter = NumberFormat('#,##0.00');
  return '$prefix${formatter.format(value.abs().toDouble())} $unit';
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
              DataCell(
                Text(
                  currency.format(
                    alert.unitPrice.multiply(alert.quantity).toDouble(),
                  ),
                ),
              ),
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
    final total = sumMoney(data.posLines.map((line) => line.total));
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
                      currency.format(line.total.toDouble()),
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
                _AmountRow(
                  label: 'Subtotal',
                  value: currency.format(total.toDouble()),
                ),
                _AmountRow(
                  label: 'VAT',
                  value: currency.format(total.percentage('14').toDouble()),
                ),
                const Divider(height: 28),
                _AmountRow(
                  label: 'Total',
                  value: currency.format(
                    total.add(total.percentage('14')).toDouble(),
                  ),
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

class _SalesWorkspace extends StatelessWidget {
  const _SalesWorkspace({
    required this.data,
    required this.workspace,
    required this.onWorkspaceSelected,
  });

  final OperixDashboardData data;
  final OperixSalesWorkspace workspace;
  final ValueChanged<OperixSalesWorkspace> onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: switch (workspace) {
        OperixSalesWorkspace.invoices => _SalesInvoicesScreen(
          invoices: data.salesInvoices,
          onCreate: () =>
              onWorkspaceSelected(OperixSalesWorkspace.createInvoice),
        ),
        OperixSalesWorkspace.createInvoice => _CreateSalesInvoiceScreen(
          onCancel: () => onWorkspaceSelected(OperixSalesWorkspace.invoices),
          onSave: () => onWorkspaceSelected(OperixSalesWorkspace.invoices),
        ),
        OperixSalesWorkspace.posOrders => const _PosOrdersScreen(),
        OperixSalesWorkspace.returns => const _SalesReturnsScreen(),
      },
    );
  }
}

class _SalesInvoicesScreen extends StatelessWidget {
  const _SalesInvoicesScreen({required this.invoices, required this.onCreate});

  final List<InvoicePreview> invoices;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = _SalesInvoiceRowData.fromInvoices(invoices);
    return _SalesPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SalesPageHeader(
            title: l10n.dashSalesInvoicesTitle,
            leading: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.dashCreateInvoice),
              style: _purpleButtonStyle(),
            ),
          ),
          const SizedBox(height: 28),
          _SalesSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: Text(l10n.dashFilters),
                    style: _softOutlinedButtonStyle(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _SearchBox(hint: l10n.dashSearchInvoiceHint)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SalesSurfaceCard(
            padding: EdgeInsets.zero,
            child: _SalesInvoiceTable(rows: rows),
          ),
        ],
      ),
    );
  }
}

class _CreateSalesInvoiceScreen extends StatefulWidget {
  const _CreateSalesInvoiceScreen({
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  State<_CreateSalesInvoiceScreen> createState() =>
      _CreateSalesInvoiceScreenState();
}

/// A working line on the invoice (product + editable quantity).
class _InvoiceLine {
  _InvoiceLine({required this.product});
  final Product product;
  int quantity = 1;

  Money get lineTotal => product.sellingPrice.multiply(quantity);
}

class _CreateSalesInvoiceScreenState extends State<_CreateSalesInvoiceScreen> {
  static const double _taxRate = 14;

  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;
  Customer? _customer;
  final List<_InvoiceLine> _lines = [];
  List<Customer> _customers = [];
  bool _saving = false;
  String? _error;

  late final SalesInvoiceRepository _invoices;
  late final ProductRepository _products;
  late final CustomerRepository _customerRepo;

  @override
  void initState() {
    super.initState();
    _invoices = context.read<SalesInvoiceRepository>();
    _products = context.read<ProductRepository>();
    _customerRepo = context.read<CustomerRepository>();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final list = await _customerRepo.list(includeInactive: false);
      if (mounted) setState(() => _customers = list);
    } catch (_) {}
  }

  Money get _subtotal =>
      _lines.fold(Money.zero(), (sum, l) => sum.add(l.lineTotal));
  Money get _tax => _subtotal.percentage('$_taxRate');
  Money get _total => _subtotal.add(_tax);

  Future<void> _pickDate({required bool isDue}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? (_dueDate ?? _invoiceDate) : _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDue) {
        _dueDate = picked;
      } else {
        _invoiceDate = picked;
      }
    });
  }

  Future<void> _addItem() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        // Sales can only invoice what's in stock, so hide out-of-stock items.
        child: _ProductPickerDialog(repository: _products, inStockOnly: true),
      ),
    );
    if (product == null) return;
    setState(() {
      final existing = _lines.indexWhere((l) => l.product.id == product.id);
      if (existing >= 0) {
        _lines[existing].quantity += 1;
      } else {
        _lines.add(_InvoiceLine(product: product));
      }
    });
  }

  void _changeQty(_InvoiceLine line, int delta) {
    setState(() {
      final next = line.quantity + delta;
      if (next <= 0) {
        _lines.remove(line);
      } else {
        line.quantity = next;
      }
    });
  }

  Future<void> _pickCustomer() async {
    final selected = await showDialog<Customer?>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: Text(context.l10n.dashChooseCustomer),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(context.l10n.dashCashCustomer),
            ),
            for (final c in _customers)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(c),
                child: Text(c.name),
              ),
          ],
        ),
      ),
    );
    setState(() => _customer = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_lines.isEmpty) {
      setState(() => _error = context.l10n.dashAddAtLeastOneItem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = SalesInvoiceDraft(
        clientId: _customer?.id,
        clientName: _customer?.name ?? context.l10n.dashCashCustomer,
        issueDate: _invoiceDate,
        taxRate: _taxRate,
        lines: [
          for (final l in _lines)
            SalesInvoiceLineDraft(
              productId: l.product.id,
              name: l.product.name,
              quantity: l.quantity,
              unitPrice: l.product.sellingPrice,
              costPrice: l.product.costPrice,
            ),
        ],
      );
      final invoice = await _invoices.create(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.dashInvoiceCreated(invoice.number)),
        ),
      );
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.dashCouldNotSaveInvoice(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SalesPageShell(
      maxWidth: 1180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SalesPageHeader(
            title: l10n.dashNewSalesInvoiceTitle,
            subtitle: l10n.dashNewSalesInvoiceSubtitle,
            trailing: IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.arrow_forward),
              tooltip: l10n.dashBack,
            ),
            leading: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.save),
                  style: _purpleButtonStyle(),
                ),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SalesSurfaceCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 920;
                final fields = [
                  _SalesFormField(
                    label: l10n.customerLabel,
                    value: _customer?.name ?? l10n.dashCashCustomer,
                    icon: Icons.keyboard_arrow_down,
                    onTap: _pickCustomer,
                  ),
                  _SalesFormField(
                    label: l10n.dashInvoiceDateLabel,
                    value: _formatArabicDate(_invoiceDate),
                    icon: Icons.calendar_today_outlined,
                    highlighted: true,
                    onTap: () => _pickDate(isDue: false),
                  ),
                  _SalesFormField(
                    label: l10n.dashDueDateLabel,
                    value: _dueDate == null
                        ? l10n.dashSelectDate
                        : _formatArabicDate(_dueDate!),
                    icon: Icons.calendar_today_outlined,
                    highlighted: true,
                    onTap: () => _pickDate(isDue: true),
                  ),
                  _SalesFormField(
                    label: l10n.dashInvoiceNumberLabel,
                    value: l10n.dashAutoGenerated,
                    readOnly: true,
                  ),
                ];
                if (narrow) {
                  return Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        if (field != fields.last) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      Expanded(child: fields[i]),
                      if (i != fields.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SalesSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SectionHeader(
                  title: l10n.dashInvoiceItems,
                  icon: Icons.description_outlined,
                  leading: FilledButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.dashAddItem),
                    style: _purpleButtonStyle(),
                  ),
                ),
                if (_lines.isEmpty)
                  const SizedBox(height: 260, child: _EmptyInvoiceItems())
                else
                  _InvoiceItemsTable(lines: _lines, onChangeQty: _changeQty),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _SalesSurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 820;
              final notes = _SalesSurfaceCard(child: const _NotesPanel());
              final summary = _SalesSurfaceCard(
                child: _InvoiceTotalsPanel(
                  subtotal: _subtotal,
                  tax: _tax,
                  total: _total,
                  taxRate: _taxRate,
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [notes, const SizedBox(height: 18), summary],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: notes),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: summary),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.save),
                  style: _purpleButtonStyle(),
                ),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable list of invoice line items with a quantity stepper and running
/// line totals.
class _InvoiceItemsTable extends StatelessWidget {
  const _InvoiceItemsTable({required this.lines, required this.onChangeQty});

  final List<_InvoiceLine> lines;
  final void Function(_InvoiceLine line, int delta) onChangeQty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(l10n.dashColItem, style: _invoiceHeadStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(l10n.dashColPrice, style: _invoiceHeadStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(l10n.dashColQty, style: _invoiceHeadStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(l10n.dashColTotal, style: _invoiceHeadStyle),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final line in lines) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    line.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_formatEgp(line.product.sellingPrice)),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onChangeQty(line, -1),
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                      ),
                      Text(
                        '${line.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onChangeQty(line, 1),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatEgp(line.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.delete,
                    onPressed: () => onChangeQty(line, -line.quantity),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

const _invoiceHeadStyle = TextStyle(
  color: Color(0xFF64748B),
  fontWeight: FontWeight.w800,
  fontSize: 12,
);

/// Invoice totals (subtotal, VAT, grand total) computed from the line items.
class _InvoiceTotalsPanel extends StatelessWidget {
  const _InvoiceTotalsPanel({
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.taxRate,
  });

  final Money subtotal;
  final Money tax;
  final Money total;
  final double taxRate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(l10n.subtotal, _formatEgp(subtotal)),
        const SizedBox(height: 10),
        _row(l10n.dashVatLabel(taxRate.toStringAsFixed(0)), _formatEgp(tax)),
        const Divider(height: 28),
        _row(l10n.total, _formatEgp(total), strong: true),
      ],
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
      fontSize: strong ? 18 : 14,
      color: const Color(0xFF111827),
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

/// Product picker backed by the live product list; pops the chosen [Product].
class _ProductPickerDialog extends StatefulWidget {
  const _ProductPickerDialog({
    required this.repository,
    this.inStockOnly = false,
  });

  final ProductRepository repository;

  /// When true, products with no stock on hand are hidden (sales invoice). The
  /// purchase picker leaves this false so out-of-stock items can be restocked.
  final bool inStockOnly;

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  late Future<List<Product>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = widget.repository.list(
      includeInactive: false,
      inStockOnly: widget.inStockOnly,
    );
  }

  void _reload() {
    setState(() {
      _future = widget.repository.list(
        search: _search,
        includeInactive: false,
        inStockOnly: widget.inStockOnly,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 590, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dashAddItems,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.dashClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                autofocus: true,
                onChanged: (value) {
                  _search = value;
                  _reload();
                },
                decoration: InputDecoration(
                  hintText: l10n.dashSearchByNameOrSku,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = snapshot.data ?? const [];
                  if (products.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.dashNoItemsFound,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${product.sku.isEmpty ? '' : '${product.sku}  '}'
                          '${l10n.dashStockLabel(product.quantityOnHand)}',
                          style: TextStyle(
                            color: product.quantityOnHand <= 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF059669),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        trailing: Text(
                          _formatEgp(product.sellingPrice),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        onTap: () => Navigator.of(context).pop(product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosOrdersScreen extends StatelessWidget {
  const _PosOrdersScreen();

  @override
  Widget build(BuildContext context) {
    final rows = [
      _PosOrderRow(
        number: '#2',
        date: 'الخميس 11 يونيو 2026',
        customer: 'عميل نقدي',
        stock: 'Main Branch - Default Inventory',
        payment: 'Cash',
        items: '3',
        total: Money.of('4400'),
      ),
      _PosOrderRow(
        number: '#1',
        date: 'الأربعاء 10 يونيو 2026',
        customer: 'عميل نقدي',
        stock: 'Main Branch - Default Inventory',
        payment: 'Cash',
        items: '2',
        total: Money.of('2100'),
      ),
    ];
    return _SalesPageShell(
      maxWidth: 1240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CenteredTitle(
            title: 'طلبات نقاط البيع',
            subtitle: '2 طلب موجود',
          ),
          const SizedBox(height: 22),
          const Align(alignment: Alignment.center, child: _DateRangePill()),
          const SizedBox(height: 26),
          _SalesSurfaceCard(
            padding: EdgeInsets.zero,
            child: _PosOrdersTable(rows: rows),
          ),
        ],
      ),
    );
  }
}

class _SalesReturnsScreen extends StatelessWidget {
  const _SalesReturnsScreen();

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ReturnRow(
        number: '#3',
        date: 'الجمعة 12 يونيو 2026',
        customer: 'عميل نقدي',
        total: Money.of('2200'),
        status: 'مكتمل',
      ),
      _ReturnRow(
        number: '#2',
        date: 'الجمعة 12 يونيو 2026',
        customer: 'عميل نقدي',
        total: Money.of('1500'),
        status: 'مكتمل',
      ),
      _ReturnRow(
        number: '#1',
        date: 'الخميس 11 يونيو 2026',
        customer: 'عميل نقدي',
        total: Money.of('300'),
        status: 'موافق عليه',
      ),
    ];
    return _SalesPageShell(
      maxWidth: 1220,
      child: _SalesSurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const _SectionHeader(
              title: 'المرتجعات الأخيرة',
              leading: _StatusTabs(),
            ),
            _ReturnsTable(rows: rows),
          ],
        ),
      ),
    );
  }
}

class _PurchaseWorkspace extends StatelessWidget {
  const _PurchaseWorkspace({
    required this.data,
    required this.workspace,
    required this.onWorkspaceSelected,
  });

  final OperixDashboardData data;
  final OperixPurchaseWorkspace workspace;
  final ValueChanged<OperixPurchaseWorkspace> onWorkspaceSelected;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: switch (workspace) {
        OperixPurchaseWorkspace.invoices => _InvoiceWorkspace(
          title: 'Purchase invoices',
          invoices: data.purchaseInvoices,
          emptyLabel: 'No purchase invoices loaded',
        ),
        OperixPurchaseWorkspace.createInvoice => _CreatePurchaseInvoiceScreen(
          onCancel: () => onWorkspaceSelected(OperixPurchaseWorkspace.invoices),
          onSave: () => onWorkspaceSelected(OperixPurchaseWorkspace.invoices),
        ),
      },
    );
  }
}

class _CreatePurchaseInvoiceScreen extends StatefulWidget {
  const _CreatePurchaseInvoiceScreen({
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  State<_CreatePurchaseInvoiceScreen> createState() =>
      _CreatePurchaseInvoiceScreenState();
}

/// A working purchase line: product + editable purchase price + quantity.
class _PurchaseLine {
  _PurchaseLine({required this.product})
    : priceController = TextEditingController(
        text:
            (product.costPrice.toDouble() > 0
                    ? product.costPrice
                    : product.sellingPrice)
                .toDouble()
                .toStringAsFixed(2),
      ),
      salePriceController = TextEditingController(
        text: product.sellingPrice.toDouble().toStringAsFixed(2),
      );

  final Product product;
  int quantity = 1;
  final TextEditingController priceController;
  final TextEditingController salePriceController;

  Money get unitPrice =>
      Money.fromNum(double.tryParse(priceController.text.trim()) ?? 0);

  /// New selling price to push onto the product, or null when left blank/zero so
  /// the existing catalogue price is kept. Does not affect the invoice total.
  Money? get salePrice {
    final value = double.tryParse(salePriceController.text.trim()) ?? 0;
    return value > 0 ? Money.fromNum(value) : null;
  }

  Money get lineTotal => unitPrice.multiply(quantity);
}

class _CreatePurchaseInvoiceScreenState
    extends State<_CreatePurchaseInvoiceScreen> {
  static const double _taxRate = 14;

  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now();
  Supplier? _supplier;
  final List<_PurchaseLine> _lines = [];
  List<Supplier> _suppliers = [];
  bool _saving = false;
  String? _error;

  late final PurchaseInvoiceRepository _invoices;
  late final ProductRepository _products;
  late final SupplierRepository _supplierRepo;

  @override
  void initState() {
    super.initState();
    _invoices = context.read<PurchaseInvoiceRepository>();
    _products = context.read<ProductRepository>();
    _supplierRepo = context.read<SupplierRepository>();
    _loadSuppliers();
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.priceController.dispose();
      line.salePriceController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final list = await _supplierRepo.list(includeInactive: false);
      if (mounted) setState(() => _suppliers = list);
    } catch (_) {}
  }

  Money get _subtotal =>
      _lines.fold(Money.zero(), (sum, l) => sum.add(l.lineTotal));
  Money get _tax => _subtotal.percentage('$_taxRate');
  Money get _total => _subtotal.add(_tax);

  Future<void> _pickDate({required bool isDue}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? _dueDate : _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDue) {
        _dueDate = picked;
      } else {
        _invoiceDate = picked;
      }
    });
  }

  Future<void> _addItem() async {
    final product = await showDialog<Product>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ProductPickerDialog(repository: _products),
      ),
    );
    if (product == null) return;
    setState(() {
      final existing = _lines.indexWhere((l) => l.product.id == product.id);
      if (existing >= 0) {
        _lines[existing].quantity += 1;
      } else {
        _lines.add(_PurchaseLine(product: product));
      }
    });
  }

  void _changeQty(_PurchaseLine line, int delta) {
    setState(() {
      final next = line.quantity + delta;
      if (next <= 0) {
        _lines.remove(line);
        line.priceController.dispose();
        line.salePriceController.dispose();
      } else {
        line.quantity = next;
      }
    });
  }

  Future<void> _pickSupplier() async {
    final selected = await showDialog<Supplier?>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: Text(context.l10n.dashChooseSupplier),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(context.l10n.dashNoSupplier),
            ),
            for (final s in _suppliers)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(s),
                child: Text(s.companyName),
              ),
          ],
        ),
      ),
    );
    setState(() => _supplier = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_lines.isEmpty) {
      setState(() => _error = context.l10n.dashAddAtLeastOneItem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = PurchaseInvoiceDraft(
        supplierId: _supplier?.id,
        supplierName: _supplier?.companyName ?? context.l10n.dashCashSupplier,
        issueDate: _invoiceDate,
        taxRate: _taxRate,
        lines: [
          for (final l in _lines)
            PurchaseInvoiceLineDraft(
              productId: l.product.id,
              name: l.product.name,
              quantity: l.quantity,
              unitPrice: l.unitPrice,
              salePrice: l.salePrice,
            ),
        ],
      );
      final invoice = await _invoices.create(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.dashPurchaseInvoiceCreated(invoice.number),
          ),
        ),
      );
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.dashCouldNotSaveInvoice(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SalesPageShell(
      maxWidth: 1180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SalesPageHeader(
            title: l10n.dashNewPurchaseInvoiceTitle,
            subtitle: l10n.dashNewPurchaseInvoiceSubtitle,
            trailing: IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.arrow_forward),
              tooltip: l10n.dashBack,
            ),
            leading: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.save),
                  style: _purpleButtonStyle(),
                ),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SalesSurfaceCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 920;
                final fields = [
                  _SalesFormField(
                    label: l10n.dashSupplierLabel,
                    value: _supplier?.companyName ?? l10n.dashChooseSupplier,
                    icon: Icons.keyboard_arrow_down,
                    onTap: _pickSupplier,
                  ),
                  _SalesFormField(
                    label: l10n.dashInvoiceDateLabel,
                    value: _formatArabicDate(_invoiceDate),
                    icon: Icons.calendar_today_outlined,
                    highlighted: true,
                    onTap: () => _pickDate(isDue: false),
                  ),
                  _SalesFormField(
                    label: l10n.dashDueDateLabel,
                    value: _formatArabicDate(_dueDate),
                    icon: Icons.calendar_today_outlined,
                    highlighted: true,
                    onTap: () => _pickDate(isDue: true),
                  ),
                  _SalesFormField(
                    label: l10n.dashInvoiceNumberLabel,
                    value: l10n.dashAutoGenerated,
                    readOnly: true,
                  ),
                ];
                if (narrow) {
                  return Column(
                    children: [
                      for (final field in fields) ...[
                        field,
                        if (field != fields.last) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      Expanded(child: fields[i]),
                      if (i != fields.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _SalesSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SectionHeader(
                  title: l10n.dashInvoiceItems,
                  icon: Icons.description_outlined,
                  leading: FilledButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.dashAddItem),
                    style: _purpleButtonStyle(),
                  ),
                ),
                if (_lines.isEmpty)
                  const SizedBox(height: 260, child: _PurchaseEmptyItems())
                else
                  _PurchaseItemsTable(
                    lines: _lines,
                    onChangeQty: _changeQty,
                    onPriceChanged: () => setState(() {}),
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _SalesSurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SalesSurfaceCard(
            child: _InvoiceTotalsPanel(
              subtotal: _subtotal,
              tax: _tax,
              total: _total,
              taxRate: _taxRate,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: Text(l10n.save),
                  style: _purpleButtonStyle(),
                ),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable purchase line items: product, editable unit cost, quantity, total.
class _PurchaseItemsTable extends StatelessWidget {
  const _PurchaseItemsTable({
    required this.lines,
    required this.onChangeQty,
    required this.onPriceChanged,
  });

  final List<_PurchaseLine> lines;
  final void Function(_PurchaseLine line, int delta) onChangeQty;
  final VoidCallback onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(l10n.dashColItem, style: _invoiceHeadStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.dashColPurchasePrice,
                  style: _invoiceHeadStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(l10n.dashColSalePrice, style: _invoiceHeadStyle),
              ),
              Expanded(
                flex: 3,
                child: Text(l10n.dashColQty, style: _invoiceHeadStyle),
              ),
              Expanded(
                flex: 2,
                child: Text(l10n.dashColTotal, style: _invoiceHeadStyle),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final line in lines) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    line.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: TextField(
                      controller: line.priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => onPriceChanged(),
                      decoration: const InputDecoration(
                        prefixText: 'EGP ',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: TextField(
                      controller: line.salePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'EGP ',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onChangeQty(line, -1),
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                      ),
                      Text(
                        '${line.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onChangeQty(line, 1),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatEgp(line.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.delete,
                    onPressed: () => onChangeQty(line, -line.quantity),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class _PurchaseEmptyItems extends StatelessWidget {
  const _PurchaseEmptyItems();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF818CF8),
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.dashNoItemsAdded,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.dashNoItemsAddedBody,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesPageShell extends StatelessWidget {
  const _SalesPageShell({required this.child, this.maxWidth = 1680});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _SalesPageHeader extends StatelessWidget {
  const _SalesPageHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (trailing != null) ...[trailing!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (leading != null) ...[const SizedBox(width: 12), leading!],
      ],
    );
  }
}

class _CenteredTitle extends StatelessWidget {
  const _CenteredTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SalesSurfaceCard extends StatelessWidget {
  const _SalesSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesInvoiceTable extends StatelessWidget {
  const _SalesInvoiceTable({required this.rows});

  final List<_SalesInvoiceRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SalesTableHeader(
          columns: [
            _SalesColumn('رقم الفاتورة', 2),
            _SalesColumn('العميل', 2),
            _SalesColumn('تاريخ الفاتورة', 2),
            _SalesColumn('الإجمالي', 2),
            _SalesColumn('المستحق', 2),
            _SalesColumn('الحالة', 1),
            _SalesColumn('الإجراءات', 1),
          ],
        ),
        for (final row in rows)
          _SalesTableRow(
            cells: [
              Text(row.number, style: _tableCellStyle(strong: true)),
              _CustomerChip(label: row.customer),
              Text(row.date, style: _tableCellStyle()),
              Text(_formatEgp(row.total), style: _tableCellStyle(strong: true)),
              Text(
                _formatEgp(row.due),
                style: _tableCellStyle(
                  strong: true,
                  color: row.due.isZero
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFEF4444),
                ),
              ),
              _ArabicStatusPill(label: row.status),
              _RowActions(showDelete: row.status == 'مسودة'),
            ],
            flexes: const [2, 2, 2, 2, 2, 1, 1],
          ),
      ],
    );
  }
}

class _PosOrdersTable extends StatelessWidget {
  const _PosOrdersTable({required this.rows});

  final List<_PosOrderRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SalesTableHeader(
          columns: [
            _SalesColumn('رقم الطلب', 1),
            _SalesColumn('التاريخ', 2),
            _SalesColumn('العميل', 2),
            _SalesColumn('المخزون', 3),
            _SalesColumn('الدفع', 1),
            _SalesColumn('العناصر', 1),
            _SalesColumn('الإجمالي', 2),
            _SalesColumn('الإجراءات', 1),
          ],
        ),
        for (final row in rows)
          _SalesTableRow(
            cells: [
              Text(
                row.number,
                style: _tableCellStyle(
                  strong: true,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              Text(row.date, style: _tableCellStyle()),
              _CustomerChip(label: row.customer),
              Text(row.stock, style: _tableCellStyle(strong: true)),
              _GreenChip(label: row.payment),
              _CountChip(label: row.items),
              Text(
                _formatEgp(row.total),
                style: _tableCellStyle(
                  strong: true,
                  color: const Color(0xFF059669),
                ),
              ),
              const _RowActions(showRefresh: true, showDelete: true),
            ],
            flexes: const [1, 2, 2, 3, 1, 1, 2, 1],
          ),
      ],
    );
  }
}

class _ReturnsTable extends StatelessWidget {
  const _ReturnsTable({required this.rows});

  final List<_ReturnRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SalesTableHeader(
          columns: [
            _SalesColumn('تاريخ المرتجع', 2),
            _SalesColumn('رقم المرتجع', 2),
            _SalesColumn('العميل', 2),
            _SalesColumn('المبلغ الإجمالي', 2),
            _SalesColumn('الحالة', 2),
            _SalesColumn('', 1),
          ],
        ),
        for (final row in rows)
          _SalesTableRow(
            cells: [
              Text(row.date, style: _tableCellStyle()),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(row.number, style: _tableCellStyle(strong: true)),
                  const SizedBox(height: 3),
                  const Text(
                    'من طلب نقطة بيع',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(row.customer, style: _tableCellStyle(strong: true)),
              Text(
                _formatEgp(row.total),
                style: _tableCellStyle(
                  strong: true,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              _ArabicStatusPill(label: row.status),
              const Icon(Icons.chevron_left, color: Color(0xFFCBD5E1)),
            ],
            flexes: const [2, 2, 2, 2, 2, 1],
          ),
      ],
    );
  }
}

class _SalesTableHeader extends StatelessWidget {
  const _SalesTableHeader({required this.columns});

  final List<_SalesColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  column.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SalesTableRow extends StatelessWidget {
  const _SalesTableRow({required this.cells, required this.flexes});

  final List<Widget> cells;
  final List<int> flexes;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: cells[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SalesColumn {
  const _SalesColumn(this.label, this.flex);

  final String label;
  final int flex;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon, this.leading});

  final String title;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF818CF8), size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          ?leading,
        ],
      ),
    );
  }
}

class _SalesFormField extends StatelessWidget {
  const _SalesFormField({
    required this.label,
    required this.value,
    this.icon,
    this.highlighted = false,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlighted;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFC7D2FE)
              : const Color(0xFFE2E8F0),
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (icon != null)
            Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        ],
      ),
    );

    if (onTap != null) {
      box = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(999),
          child: box,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        box,
      ],
    );
  }
}

class _EmptyInvoiceItems extends StatelessWidget {
  const _EmptyInvoiceItems();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF818CF8),
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.dashNoItemsAddedYet,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.dashNoItemsAddedYetBody,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF818CF8), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelTitle(title: l10n.dashNotes, icon: Icons.note_outlined),
        const SizedBox(height: 16),
        Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.dashNotesHint,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRangePill extends StatelessWidget {
  const _DateRangePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF94A3B8),
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'تاريخ البدء',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_back, color: Color(0xFF94A3B8), size: 16),
          SizedBox(width: 12),
          Text(
            'تاريخ الانتهاء',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 16),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs();

  @override
  Widget build(BuildContext context) {
    const tabs = ['الكل', 'قيد الانتظار', 'موافق عليه', 'مرفوض'];
    return Wrap(
      spacing: 8,
      children: [
        for (final tab in tabs)
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: tab == 'الكل' ? const Color(0xFF4F46E5) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tab == 'الكل'
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              tab,
              style: TextStyle(
                color: tab == 'الكل' ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _CustomerChip extends StatelessWidget {
  const _CustomerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD97706),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GreenChip extends StatelessWidget {
  const _GreenChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF047857),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ArabicStatusPill extends StatelessWidget {
  const _ArabicStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final draft = label == 'مسودة';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: draft ? const Color(0xFFF1F5F9) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: draft ? const Color(0xFF64748B) : const Color(0xFF15803D),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({this.showDelete = false, this.showRefresh = false});

  final bool showDelete;
  final bool showRefresh;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        if (showDelete)
          const Icon(Icons.delete_outline, size: 17, color: Color(0xFFEF4444)),
        if (showRefresh)
          const Icon(Icons.refresh, size: 17, color: Color(0xFF94A3B8)),
        const Icon(
          Icons.visibility_outlined,
          size: 17,
          color: Color(0xFF6366F1),
        ),
      ],
    );
  }
}

class _SalesInvoiceRowData {
  const _SalesInvoiceRowData({
    required this.number,
    required this.customer,
    required this.date,
    required this.total,
    required this.due,
    required this.status,
  });

  final String number;
  final String customer;
  final String date;
  final Money total;
  final Money due;
  final String status;

  static List<_SalesInvoiceRowData> fromInvoices(
    List<InvoicePreview> invoices,
  ) {
    if (invoices.isEmpty) {
      return [
        _SalesInvoiceRowData(
          number: '—',
          customer: 'عميل نقدي',
          date: 'السبت 13 يونيو 2026',
          total: Money.of('1600'),
          due: Money.of('1600'),
          status: 'مسودة',
        ),
        _SalesInvoiceRowData(
          number: 'INV-000002',
          customer: 'عميل نقدي',
          date: 'الجمعة 12 يونيو 2026',
          total: Money.of('2600'),
          due: Money.zero(),
          status: 'مدفوعة',
        ),
        _SalesInvoiceRowData(
          number: 'SI-000001',
          customer: 'عميل نقدي',
          date: 'الجمعة 12 يونيو 2026',
          total: Money.of('3780'),
          due: Money.zero(),
          status: 'مدفوعة',
        ),
      ];
    }

    final dateFormat = DateFormat('yyyy/MM/dd');
    return [
      for (final invoice in invoices)
        _SalesInvoiceRowData(
          number: invoice.number,
          customer: invoice.party,
          date: dateFormat.format(invoice.issueDate),
          total: invoice.amount,
          due: invoice.status.toLowerCase().contains('paid')
              ? Money.zero()
              : invoice.amount,
          status: invoice.status.toLowerCase().contains('paid')
              ? 'مدفوعة'
              : 'مسودة',
        ),
    ];
  }
}

class _PosOrderRow {
  const _PosOrderRow({
    required this.number,
    required this.date,
    required this.customer,
    required this.stock,
    required this.payment,
    required this.items,
    required this.total,
  });

  final String number;
  final String date;
  final String customer;
  final String stock;
  final String payment;
  final String items;
  final Money total;
}

class _ReturnRow {
  const _ReturnRow({
    required this.number,
    required this.date,
    required this.customer,
    required this.total,
    required this.status,
  });

  final String number;
  final String date;
  final String customer;
  final Money total;
  final String status;
}

TextStyle _tableCellStyle({bool strong = false, Color? color}) {
  return TextStyle(
    color: color ?? const Color(0xFF334155),
    fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
    fontSize: 13,
  );
}

ButtonStyle _purpleButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: const Color(0xFF4F46E5),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.w900),
  );
}

ButtonStyle _softOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF334155),
    side: const BorderSide(color: Color(0xFFE2E8F0)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontWeight: FontWeight.w900),
  );
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
              DataCell(Text(currency.format(invoice.amount.toDouble()))),
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
              DataCell(Text(currency.format(record.balance.toDouble()))),
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

  void _showReportPending(BuildContext context, String reportName) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(content: Text('$reportName is not available yet.')),
    );
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionRow(
              Icons.balance,
              'Trial balance',
              onPressed: () => _showReportPending(context, 'Trial balance'),
            ),
            _ActionRow(
              Icons.account_tree_outlined,
              'General ledger',
              onPressed: () => _showReportPending(context, 'General ledger'),
            ),
            _ActionRow(
              Icons.query_stats,
              'Profit and loss',
              onPressed: () => _showReportPending(context, 'Profit and loss'),
            ),
            _ActionRow(
              Icons.receipt_long,
              'Tax summary',
              onPressed: () => _showReportPending(context, 'Tax summary'),
            ),
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
  const _ChipLabel({required this.label});

  final String label;
  static const _color = Color(0xFF0F766E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withAlpha(54)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(this.icon, this.label, {this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconColor = onPressed == null
        ? const Color(0xFF64748B)
        : const Color(0xFF0F766E);
    final row = Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        if (onPressed != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF64748B)),
        ],
      ],
    );

    if (onPressed == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: row);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: row,
            ),
          ),
        ),
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
