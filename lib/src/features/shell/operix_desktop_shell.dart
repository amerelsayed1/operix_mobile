import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/app_session.dart';
import '../../app/l10n_ext.dart';
import '../../app/language_toggle.dart';
import '../../config/database_config.dart';
import '../../data/business_repository.dart';
import '../../data/operix_repository.dart';
import '../../domain/business_profile.dart';
import '../../domain/operix_models.dart';
import '../../domain/pos_models.dart';
import '../customers/customers_screen.dart';
import '../dashboard/operix_dashboard.dart';
import '../inventory/inventory_screen.dart';
import '../pos/pos_orders_screen.dart';
import '../pos/pos_workspace.dart';
import '../pos/sales_returns_screen.dart';
import '../reports/sales_report_screen.dart';
import '../settings/settings_workspace.dart';
import '../suppliers/suppliers_screen.dart';
import '../users/users_screen.dart';

class OperixDesktopShell extends StatefulWidget {
  const OperixDesktopShell({super.key});

  @override
  State<OperixDesktopShell> createState() => _OperixDesktopShellState();
}

class _OperixDesktopShellState extends State<OperixDesktopShell> {
  OperixModule _selectedModule = OperixModule.dashboard;
  OperixSalesWorkspace _salesWorkspace = OperixSalesWorkspace.invoices;
  OperixPurchaseWorkspace _purchaseWorkspace = OperixPurchaseWorkspace.invoices;

  /// Set when an "Add …" sidebar item is tapped so the destination screen opens
  /// its create form on arrival. Cleared once the screen consumes it.
  OperixModule? _pendingCreate;
  int _businessBadgeReload = 0;
  late final OperixRepository _repository;
  late final DatabaseConfig _databaseConfig;
  late Future<OperixDashboardData> _dashboardFuture;

  /// Last successfully loaded dashboard data, retained so a period re-fetch can
  /// keep the dashboard (and its period tabs) on screen instead of flashing a
  /// full-screen spinner.
  OperixDashboardData? _lastDashboardData;

  /// Selected dashboard reporting window (defaults to this month, matching the
  /// default period tab). Re-fetches the dashboard whenever it changes.
  DashboardPeriod _period = const DashboardPeriod.thisMonth();

  @override
  void initState() {
    super.initState();
    _repository = context.read<OperixRepository>();
    _databaseConfig = context.read<DatabaseConfig>();
    _dashboardFuture = _repository.loadDashboard(period: _period);

    // Land on the first module the user can actually open (a cashier without
    // dashboard access shouldn't boot into an access-denied screen).
    final session = context.read<AppSession>();
    if (!session.canAccessModule(_selectedModule)) {
      for (final module in OperixModule.values) {
        if (session.canAccessModule(module)) {
          _selectedModule = module;
          break;
        }
      }
    }
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _repository.loadDashboard(period: _period);
    });
  }

  void _onPeriodChanged(DashboardPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _dashboardFuture = _repository.loadDashboard(period: period);
    });
  }

  /// Whether the navigation sidebar is collapsed (hidden). Toggled from the top
  /// bar; the toggle stays visible so the sidebar can always be restored.
  bool _sidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  void _selectModule(OperixModule module) {
    setState(() {
      _selectedModule = module;
      _pendingCreate = null;
    });
  }

  /// Navigate to [module] and ask its screen to open the create form.
  void _selectModuleForCreate(OperixModule module) {
    setState(() {
      _selectedModule = module;
      _pendingCreate = module;
    });
  }

  void _consumePendingCreate() {
    if (_pendingCreate == null) return;
    setState(() => _pendingCreate = null);
  }

  void _selectSalesWorkspace(OperixSalesWorkspace workspace) {
    setState(() {
      _selectedModule = OperixModule.sales;
      _salesWorkspace = workspace;
    });
  }

  void _selectPurchaseWorkspace(OperixPurchaseWorkspace workspace) {
    setState(() {
      _selectedModule = OperixModule.purchases;
      _purchaseWorkspace = workspace;
    });
  }

  Widget _topBar() {
    return _TopBar(
      module: _selectedModule,
      onRefresh: _refresh,
      onLogout: () => context.read<AppSession>().signOut(),
      onPosSelected: () => _selectModule(OperixModule.pointOfSale),
      onToggleSidebar: _toggleSidebar,
      sidebarCollapsed: _sidebarCollapsed,
    );
  }

  Widget _body() {
    // Access control: never render a module the signed-in user isn't permitted
    // to open, even if it somehow becomes selected. The sidebar hides these too,
    // but this is the authoritative gate.
    if (!context.read<AppSession>().canAccessModule(_selectedModule)) {
      return const _AccessDenied();
    }
    if (_selectedModule == OperixModule.pointOfSale) {
      return const PosWorkspace();
    }
    if (_selectedModule == OperixModule.inventory) {
      return const InventoryProductsScreen();
    }
    if (_selectedModule == OperixModule.clients) {
      return CustomersScreen(
        autoCreate: _pendingCreate == OperixModule.clients,
        onAutoCreateConsumed: _consumePendingCreate,
      );
    }
    if (_selectedModule == OperixModule.suppliers) {
      return SuppliersScreen(
        autoCreate: _pendingCreate == OperixModule.suppliers,
        onAutoCreateConsumed: _consumePendingCreate,
      );
    }
    if (_selectedModule == OperixModule.users) {
      return UsersScreen(
        autoCreate: _pendingCreate == OperixModule.users,
        onAutoCreateConsumed: _consumePendingCreate,
      );
    }
    if (_selectedModule == OperixModule.sales &&
        _salesWorkspace == OperixSalesWorkspace.posOrders) {
      return const PosOrdersScreen();
    }
    if (_selectedModule == OperixModule.sales &&
        _salesWorkspace == OperixSalesWorkspace.returns) {
      return const SalesReturnsScreen();
    }
    if (_selectedModule == OperixModule.reports) {
      return const SalesReportScreen();
    }
    if (_selectedModule == OperixModule.settings) {
      return FutureBuilder<OperixDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SettingsWorkspace(
            status: snapshot.requireData.connectionStatus,
            databaseConfig: _databaseConfig,
            onBusinessChanged: () {
              setState(() => _businessBadgeReload++);
            },
          );
        },
      );
    }
    return FutureBuilder<OperixDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        // Keep showing the previous dashboard while a period change re-fetches,
        // so the period tabs don't flash to a spinner (mirrors the web).
        if (snapshot.hasData) _lastDashboardData = snapshot.data;
        final data = snapshot.data ?? _lastDashboardData;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return OperixDashboard(
          selectedModule: _selectedModule,
          data: data,
          databaseConfig: _databaseConfig,
          onModuleSelected: _selectModule,
          selectedPeriod: _period,
          onPeriodChanged: _onPeriodChanged,
          salesWorkspace: _salesWorkspace,
          onSalesWorkspaceSelected: _selectSalesWorkspace,
          purchaseWorkspace: _purchaseWorkspace,
          onPurchaseWorkspaceSelected: _selectPurchaseWorkspace,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            collapsed: _sidebarCollapsed,
            selectedModule: _selectedModule,
            selectedSalesWorkspace: _salesWorkspace,
            selectedPurchaseWorkspace: _purchaseWorkspace,
            businessBadgeReload: _businessBadgeReload,
            onSelected: _selectModule,
            onCreateSelected: _selectModuleForCreate,
            onSalesWorkspaceSelected: _selectSalesWorkspace,
            onPurchaseWorkspaceSelected: _selectPurchaseWorkspace,
          ),
          Expanded(
            child: Column(
              children: [
                _topBar(),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            l10n.accessDeniedTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.accessDeniedBody,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.collapsed,
    required this.selectedModule,
    required this.selectedSalesWorkspace,
    required this.selectedPurchaseWorkspace,
    required this.businessBadgeReload,
    required this.onSelected,
    required this.onCreateSelected,
    required this.onSalesWorkspaceSelected,
    required this.onPurchaseWorkspaceSelected,
  });

  final bool collapsed;
  final OperixModule selectedModule;
  final OperixSalesWorkspace selectedSalesWorkspace;
  final OperixPurchaseWorkspace selectedPurchaseWorkspace;
  final int businessBadgeReload;
  final ValueChanged<OperixModule> onSelected;
  final ValueChanged<OperixModule> onCreateSelected;
  final ValueChanged<OperixSalesWorkspace> onSalesWorkspaceSelected;
  final ValueChanged<OperixPurchaseWorkspace> onPurchaseWorkspaceSelected;

  @override
  State<_Sidebar> createState() => _SidebarState();

  static const _dashboard = _MenuLeaf(
    en: 'Dashboard',
    ar: 'لوحة التحكم',
    icon: Icons.dashboard_outlined,
    module: OperixModule.dashboard,
    primary: true,
  );

  static const _settings = _MenuLeaf(
    en: 'Settings',
    ar: 'الإعدادات',
    icon: Icons.settings_outlined,
    module: OperixModule.settings,
    primary: true,
  );

  static const _sections = [
    _MenuGroup(
      en: 'Finance',
      ar: 'المالية',
      icon: Icons.account_balance,
      module: OperixModule.sales,
      activeModules: [
        OperixModule.sales,
        OperixModule.pointOfSale,
        OperixModule.purchases,
      ],
      children: [
        _MenuGroup(
          en: 'Sales',
          ar: 'المبيعات',
          icon: Icons.trending_up,
          module: OperixModule.sales,
          activeModules: [OperixModule.sales, OperixModule.pointOfSale],
          children: [
            _MenuLeaf(
              en: 'Sales invoices',
              ar: 'فواتير المبيعات',
              icon: Icons.format_list_bulleted,
              module: OperixModule.sales,
              salesWorkspace: OperixSalesWorkspace.invoices,
              primary: true,
            ),
            _MenuLeaf(
              en: 'New sales invoice',
              ar: 'فاتورة مبيعات جديدة',
              icon: Icons.add,
              module: OperixModule.sales,
              salesWorkspace: OperixSalesWorkspace.createInvoice,
            ),
            _MenuLeaf(
              en: 'POS orders',
              ar: 'طلبات نقاط البيع',
              icon: Icons.receipt_long,
              module: OperixModule.sales,
              salesWorkspace: OperixSalesWorkspace.posOrders,
            ),
            _MenuLeaf(
              en: 'POS',
              ar: 'نقطة البيع',
              icon: Icons.point_of_sale,
              module: OperixModule.pointOfSale,
              primary: true,
            ),
            _MenuLeaf(
              en: 'Sales returns',
              ar: 'مرتجعات المبيعات',
              icon: Icons.refresh,
              module: OperixModule.sales,
              salesWorkspace: OperixSalesWorkspace.returns,
            ),
          ],
        ),
        _MenuGroup(
          en: 'Purchases',
          ar: 'المشتريات',
          icon: Icons.inventory_2_outlined,
          module: OperixModule.purchases,
          activeModules: [OperixModule.purchases],
          children: [
            _MenuLeaf(
              en: 'Purchase invoices',
              ar: 'فواتير الشراء',
              icon: Icons.format_list_bulleted,
              module: OperixModule.purchases,
              purchaseWorkspace: OperixPurchaseWorkspace.invoices,
              primary: true,
            ),
            _MenuLeaf(
              en: 'Create purchase invoice',
              ar: 'إنشاء فاتورة شراء',
              icon: Icons.add,
              module: OperixModule.purchases,
              purchaseWorkspace: OperixPurchaseWorkspace.createInvoice,
            ),
            _MenuLeaf(
              en: 'Purchase returns',
              ar: 'مرتجعات المشتريات',
              icon: Icons.refresh,
              module: OperixModule.purchases,
            ),
            _MenuLeaf(
              en: 'Due invoices',
              ar: 'الفواتير المستحقة',
              icon: Icons.attach_money,
              module: OperixModule.accounting,
            ),
          ],
        ),
      ],
    ),
    _MenuGroup(
      en: 'Warehouses',
      ar: 'المخازن',
      icon: Icons.inventory_2_outlined,
      module: OperixModule.inventory,
      activeModules: [OperixModule.inventory],
      children: [
        _MenuLeaf(
          en: 'All warehouses',
          ar: 'جميع المخازن',
          icon: Icons.format_list_bulleted,
          module: OperixModule.inventory,
        ),
        _MenuLeaf(
          en: 'Add warehouse',
          ar: 'إضافة مخزن',
          icon: Icons.add,
          module: OperixModule.inventory,
        ),
        _MenuLeaf(
          en: 'Stock count',
          ar: 'جرد المخزون',
          icon: Icons.fact_check_outlined,
          module: OperixModule.inventory,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Branches',
      ar: 'الفروع',
      icon: Icons.business_outlined,
      module: OperixModule.settings,
      activeModules: [OperixModule.settings],
      children: [
        _MenuLeaf(
          en: 'Branch list',
          ar: 'قائمة الفروع',
          icon: Icons.format_list_bulleted,
          module: OperixModule.settings,
        ),
        _MenuLeaf(
          en: 'Add branch',
          ar: 'إضافة فرع',
          icon: Icons.add,
          module: OperixModule.settings,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Inventory',
      ar: 'الاصناف',
      icon: Icons.inventory_2_outlined,
      module: OperixModule.inventory,
      activeModules: [OperixModule.inventory],
      children: [
        _MenuLeaf(
          en: 'Items',
          ar: 'الاصناف',
          icon: Icons.format_list_bulleted,
          module: OperixModule.inventory,
          primary: true,
        ),
        _MenuLeaf(
          en: 'Add item',
          ar: 'إضافة صنف',
          icon: Icons.add,
          module: OperixModule.inventory,
        ),
        _MenuLeaf(
          en: 'Print barcode',
          ar: 'طباعة الباركود',
          icon: Icons.inventory_2_outlined,
          module: OperixModule.inventory,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Customers',
      ar: 'العملاء',
      icon: Icons.groups_2_outlined,
      module: OperixModule.clients,
      activeModules: [OperixModule.clients],
      children: [
        _MenuLeaf(
          en: 'All customers',
          ar: 'كل العملاء',
          icon: Icons.format_list_bulleted,
          module: OperixModule.clients,
          primary: true,
        ),
        _MenuLeaf(
          en: 'Add customer',
          ar: 'إضافة عميل',
          icon: Icons.add,
          module: OperixModule.clients,
          createIntent: true,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Suppliers',
      ar: 'الموردين',
      icon: Icons.local_shipping_outlined,
      module: OperixModule.suppliers,
      activeModules: [OperixModule.suppliers],
      children: [
        _MenuLeaf(
          en: 'All suppliers',
          ar: 'كل الموردين',
          icon: Icons.format_list_bulleted,
          module: OperixModule.suppliers,
          primary: true,
        ),
        _MenuLeaf(
          en: 'Add supplier',
          ar: 'إضافة مورد',
          icon: Icons.add,
          module: OperixModule.suppliers,
          createIntent: true,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Costs',
      ar: 'التكاليف',
      icon: Icons.request_quote_outlined,
      module: OperixModule.accounting,
      activeModules: [OperixModule.accounting],
      children: [
        _MenuLeaf(
          en: 'Cost list',
          ar: 'قائمة التكاليف',
          icon: Icons.format_list_bulleted,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Add cost',
          ar: 'إضافة تكلفة',
          icon: Icons.add,
          module: OperixModule.accounting,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Reports',
      ar: 'التقارير',
      icon: Icons.description_outlined,
      module: OperixModule.reports,
      activeModules: [OperixModule.reports],
      children: [
        _MenuLeaf(
          en: 'Shift reports',
          ar: 'تقارير الورديات',
          icon: Icons.description_outlined,
          module: OperixModule.reports,
          primary: true,
        ),
        _MenuLeaf(
          en: 'Product insights',
          ar: 'رؤى المنتجات',
          icon: Icons.trending_up,
          module: OperixModule.reports,
        ),
        _MenuLeaf(
          en: 'Trial balance',
          ar: 'ميزان المراجعة',
          icon: Icons.bar_chart_outlined,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Income statement',
          ar: 'قائمة الدخل',
          icon: Icons.attach_money,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Balance sheet',
          ar: 'الميزانية العمومية',
          icon: Icons.account_balance,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'General ledger',
          ar: 'دفتر الأستاذ العام',
          icon: Icons.receipt_long,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Stock variance report',
          ar: 'تقرير فروق الجرد',
          icon: Icons.fact_check_outlined,
          module: OperixModule.reports,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Users',
      ar: 'المستخدمون',
      icon: Icons.work_outline,
      module: OperixModule.users,
      activeModules: [OperixModule.users],
      children: [
        _MenuLeaf(
          en: 'All users',
          ar: 'كل المستخدمين',
          icon: Icons.format_list_bulleted,
          module: OperixModule.users,
          primary: true,
        ),
        _MenuLeaf(
          en: 'Add user',
          ar: 'إضافة مستخدم',
          icon: Icons.add,
          module: OperixModule.users,
          createIntent: true,
        ),
      ],
    ),
    _MenuGroup(
      en: 'Accounting',
      ar: 'الحسابات',
      icon: Icons.paid_outlined,
      module: OperixModule.accounting,
      activeModules: [OperixModule.accounting],
      children: [
        _MenuLeaf(
          en: 'Accounts',
          ar: 'الحسابات',
          icon: Icons.account_balance_wallet_outlined,
          module: OperixModule.accounting,
          primary: true,
        ),
        _MenuLeaf(
          en: 'Transfers',
          ar: 'التحويلات',
          icon: Icons.swap_horiz,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Chart of accounts',
          ar: 'دليل الحسابات',
          icon: Icons.account_tree_outlined,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Journal entries',
          ar: 'قيود اليومية',
          icon: Icons.menu_book_outlined,
          module: OperixModule.accounting,
        ),
        _MenuLeaf(
          en: 'Accounting periods',
          ar: 'الفترات المحاسبية',
          icon: Icons.calendar_today_outlined,
          module: OperixModule.accounting,
        ),
      ],
    ),
  ];
}

class _SidebarState extends State<_Sidebar> {
  late final Set<String> _expandedGroups;

  @override
  void initState() {
    super.initState();
    _expandedGroups = <String>{};
    _expandActiveGroups(widget.selectedModule);
  }

  @override
  void didUpdateWidget(covariant _Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedModule != widget.selectedModule) {
      _expandActiveGroups(widget.selectedModule);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collapse animates the rail width to zero while the 300-wide content keeps
    // its layout (clipped), so the toggle in the top bar slides it in/out.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: widget.collapsed ? 0 : 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: BorderDirectional(start: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minWidth: 300,
          maxWidth: 300,
          child: SizedBox(
            width: 300,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SidebarBrandHeader(),
                  Expanded(
                    child: ListView(
                      cacheExtent: 4000,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      children: [
                        _buildLeaf(context, _Sidebar._dashboard, depth: 0),
                        const SizedBox(height: 8),
                        for (final section in _Sidebar._sections)
                          _buildGroup(context, section, depth: 0),
                        const SizedBox(height: 8),
                        _buildLeaf(context, _Sidebar._settings, depth: 0),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _WorkspaceBadge(
                      reloadToken: widget.businessBadgeReload,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _expandActiveGroups(OperixModule module) {
    _expandedGroups.addAll(_activeGroupKeys(_Sidebar._sections, module));
  }

  Iterable<String> _activeGroupKeys(
    List<_MenuNode> nodes,
    OperixModule module,
  ) sync* {
    for (final node in nodes) {
      if (node is _MenuGroup) {
        final childKeys = _activeGroupKeys(node.children, module).toList();
        final directLeafActive = node.children.whereType<_MenuLeaf>().any(
          (leaf) => leaf.module == module,
        );
        if (node.activeModules.contains(module) ||
            directLeafActive ||
            childKeys.isNotEmpty) {
          yield node.key;
        }
        yield* childKeys;
      }
    }
  }

  void _toggleGroup(_MenuGroup group) {
    setState(() {
      if (_expandedGroups.contains(group.key)) {
        _expandedGroups.remove(group.key);
      } else {
        _expandedGroups.add(group.key);
      }
    });
  }

  Widget _buildNode(
    BuildContext context,
    _MenuNode node, {
    required int depth,
  }) {
    if (node is _MenuGroup) {
      return _buildGroup(context, node, depth: depth);
    }
    return _buildLeaf(context, node as _MenuLeaf, depth: depth);
  }

  /// Whether [node] (and, for groups, any descendant leaf) is reachable by the
  /// signed-in user. Used to hide navigation the user has no permission for.
  bool _nodeVisible(BuildContext context, _MenuNode node) {
    final session = context.read<AppSession>();
    if (node is _MenuLeaf) {
      return session.canAccessModule(node.module);
    }
    final group = node as _MenuGroup;
    return group.children.any((child) => _nodeVisible(context, child));
  }

  Widget _buildGroup(
    BuildContext context,
    _MenuGroup group, {
    required int depth,
  }) {
    // Hide a group entirely when the user can't reach any of its items.
    if (!_nodeVisible(context, group)) return const SizedBox.shrink();
    final active = group.activeModules.contains(widget.selectedModule);
    final selected = group.module == widget.selectedModule;
    final expanded = _expandedGroups.contains(group.key);
    final collapsedIcon = Directionality.of(context) == TextDirection.rtl
        ? Icons.keyboard_arrow_left
        : Icons.keyboard_arrow_right;
    return Padding(
      padding: EdgeInsets.only(top: depth == 0 ? 8 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MenuTile(
            label: group.label(context),
            icon: group.icon,
            selected: selected,
            active: active,
            depth: depth,
            trailing: expanded ? Icons.keyboard_arrow_down : collapsedIcon,
            onTap: () => _toggleGroup(group),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: expanded
                ? Padding(
                    key: ValueKey('${group.key}-open'),
                    padding: EdgeInsetsDirectional.only(
                      start: depth == 0 ? 14 : 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final child in group.children)
                          _buildNode(context, child, depth: depth + 1),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('closed')),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaf(
    BuildContext context,
    _MenuLeaf leaf, {
    required int depth,
  }) {
    // Hide leaves the user has no permission to open.
    if (!context.read<AppSession>().canAccessModule(leaf.module)) {
      return const SizedBox.shrink();
    }
    final selected =
        leaf.primary && widget.selectedModule == leaf.module ||
        leaf.salesWorkspace != null &&
            widget.selectedModule == OperixModule.sales &&
            widget.selectedSalesWorkspace == leaf.salesWorkspace ||
        leaf.purchaseWorkspace != null &&
            widget.selectedModule == OperixModule.purchases &&
            widget.selectedPurchaseWorkspace == leaf.purchaseWorkspace;
    return _MenuTile(
      label: leaf.label(context),
      icon: leaf.icon,
      selected: selected,
      active: selected,
      depth: depth,
      onTap: () {
        final salesWorkspace = leaf.salesWorkspace;
        if (salesWorkspace != null) {
          widget.onSalesWorkspaceSelected(salesWorkspace);
        } else if (leaf.purchaseWorkspace != null) {
          widget.onPurchaseWorkspaceSelected(leaf.purchaseWorkspace!);
        } else if (leaf.createIntent) {
          widget.onCreateSelected(leaf.module);
        } else {
          widget.onSelected(leaf.module);
        }
      },
    );
  }
}

class _SidebarBrandHeader extends StatelessWidget {
  const _SidebarBrandHeader();

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Image.asset(
          isRtl ? 'assets/brand/logo-ar.png' : 'assets/brand/logo.png',
          semanticLabel: 'Operix logo',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

abstract class _MenuNode {
  const _MenuNode();
}

class _MenuGroup extends _MenuNode {
  const _MenuGroup({
    required this.en,
    required this.ar,
    required this.icon,
    required this.children,
    this.module,
    this.activeModules = const [],
  });

  final String en;
  final String ar;
  final IconData icon;
  final OperixModule? module;
  final List<OperixModule> activeModules;
  final List<_MenuNode> children;

  String get key => en;

  String label(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl ? ar : en;
  }
}

class _MenuLeaf extends _MenuNode {
  const _MenuLeaf({
    required this.en,
    required this.ar,
    required this.icon,
    required this.module,
    this.salesWorkspace,
    this.purchaseWorkspace,
    this.primary = false,
    this.createIntent = false,
  });

  final String en;
  final String ar;
  final IconData icon;
  final OperixModule module;
  final OperixSalesWorkspace? salesWorkspace;
  final OperixPurchaseWorkspace? purchaseWorkspace;
  final bool primary;

  /// When true, tapping this leaf opens the destination module's create form
  /// instead of just showing its list (e.g. "Add customer").
  final bool createIntent;

  String label(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl ? ar : en;
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.active,
    required this.depth,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool active;
  final int depth;
  final VoidCallback? onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final foreground = selected || active
        ? const Color(0xFF4F46E5)
        : const Color(0xFF334155);
    final tileHeight = depth == 0 ? 42.0 : 36.0;
    return Tooltip(
      message: label,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: depth * 8,
          top: depth == 0 ? 3 : 1,
          bottom: depth == 0 ? 3 : 1,
        ),
        child: Material(
          color: selected ? const Color(0xFFF4F1FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            mouseCursor: onTap == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(8),
            hoverColor: const Color(0xFFF8FAFC),
            child: SizedBox(
              height: tileHeight,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(icon, size: depth == 0 ? 20 : 18, color: foreground),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: depth == 0 ? 14 : 13,
                          fontWeight: depth == 0 || active
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Icon(
                        trailing,
                        size: 18,
                        color: active
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF94A3B8),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceBadge extends StatefulWidget {
  const _WorkspaceBadge({required this.reloadToken});

  final int reloadToken;

  @override
  State<_WorkspaceBadge> createState() => _WorkspaceBadgeState();
}

class _WorkspaceBadgeState extends State<_WorkspaceBadge> {
  late Future<BusinessProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<BusinessRepository>().loadProfile();
  }

  @override
  void didUpdateWidget(covariant _WorkspaceBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _profileFuture = context.read<BusinessRepository>().loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSession>().user;
    return FutureBuilder<BusinessProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile =
            snapshot.data ??
            const BusinessProfile(
              businessName: 'Operix Business',
              branchName: 'Main branch',
            );

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => context.read<AppSession>().signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(context.l10n.signOut),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _BusinessAvatar(profile: profile),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? profile.businessName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.username ?? profile.branchName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusinessAvatar extends StatelessWidget {
  const _BusinessAvatar({required this.profile});

  final BusinessProfile profile;

  @override
  Widget build(BuildContext context) {
    final logoPath = profile.logoPath?.trim();
    final initials = Text(
      profile.initials,
      style: const TextStyle(
        color: Color(0xFF4F46E5),
        fontWeight: FontWeight.w900,
        fontSize: 12,
      ),
    );

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFEDE9FE),
      child: ClipOval(
        // Avoid synchronous File.existsSync() on the UI thread: let Image.file
        // load asynchronously and fall back to initials via errorBuilder when
        // the path is missing or unreadable.
        child: (logoPath == null || logoPath.isEmpty)
            ? initials
            : Image.file(
                File(logoPath),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.module,
    required this.onRefresh,
    required this.onLogout,
    required this.onPosSelected,
    required this.onToggleSidebar,
    required this.sidebarCollapsed,
  });

  final OperixModule module;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onPosSelected;
  final VoidCallback onToggleSidebar;
  final bool sidebarCollapsed;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppSession>().user;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Tooltip(
            message: Directionality.of(context) == TextDirection.rtl
                ? 'القائمة الجانبية'
                : 'Toggle sidebar',
            child: IconButton(
              onPressed: onToggleSidebar,
              icon: Icon(sidebarCollapsed ? Icons.menu : Icons.menu_open),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _moduleTitle(context, module),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF182521),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.desktopWorkspace,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF66756F),
                  ),
                ),
              ],
            ),
          ),
          const LanguageToggle(),
          const SizedBox(width: 4),
          const _FullscreenToggleButton(),
          const SizedBox(width: 4),
          Tooltip(
            message: context.l10n.refresh,
            child: IconButton.filledTonal(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: context.l10n.titlePointOfSale,
            child: IconButton.filledTonal(
              onPressed: onPosSelected,
              icon: const Icon(Icons.point_of_sale),
            ),
          ),
          if (user != null) ...[
            const SizedBox(width: 16),
            _UserMenu(user: user, onLogout: onLogout),
          ],
        ],
      ),
    );
  }

  String _moduleTitle(BuildContext context, OperixModule module) {
    final l10n = context.l10n;
    switch (module) {
      case OperixModule.dashboard:
        return l10n.navDashboard;
      case OperixModule.pointOfSale:
        return l10n.titlePointOfSale;
      case OperixModule.sales:
        return l10n.navSales;
      case OperixModule.purchases:
        return l10n.navPurchases;
      case OperixModule.inventory:
        return l10n.navInventory;
      case OperixModule.clients:
        return l10n.navClients;
      case OperixModule.suppliers:
        return l10n.navSuppliers;
      case OperixModule.reports:
        return l10n.navReports;
      case OperixModule.accounting:
        return l10n.navAccounting;
      case OperixModule.users:
        return l10n.navUsers;
      case OperixModule.settings:
        return l10n.navSettings;
    }
  }
}

class _FullscreenToggleButton extends StatefulWidget {
  const _FullscreenToggleButton();

  @override
  State<_FullscreenToggleButton> createState() =>
      _FullscreenToggleButtonState();
}

class _FullscreenToggleButtonState extends State<_FullscreenToggleButton>
    with WindowListener {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncFullScreenState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) {
      setState(() => _isFullScreen = true);
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) {
      setState(() => _isFullScreen = false);
    }
  }

  Future<void> _syncFullScreenState() async {
    final isFullScreen = await windowManager.isFullScreen();
    if (!mounted) {
      return;
    }
    setState(() => _isFullScreen = isFullScreen);
  }

  Future<void> _toggleFullScreen() async {
    final nextValue = !_isFullScreen;
    await windowManager.setFullScreen(nextValue);
    if (!mounted) {
      return;
    }
    setState(() => _isFullScreen = nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _isFullScreen
          ? context.l10n.exitFullScreen
          : context.l10n.enterFullScreen,
      child: IconButton.filledTonal(
        onPressed: _toggleFullScreen,
        icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.account,
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout),
            title: Text(context.l10n.signOut),
          ),
        ),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0F766E),
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF182521),
                ),
              ),
              Text(
                user.role,
                style: const TextStyle(color: Color(0xFF66756F), fontSize: 12),
              ),
            ],
          ),
          const Icon(Icons.arrow_drop_down, color: Color(0xFF66756F)),
        ],
      ),
    );
  }
}
