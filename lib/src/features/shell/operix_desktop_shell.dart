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
import '../dashboard/operix_dashboard.dart';
import '../inventory/inventory_screen.dart';
import '../pos/pos_workspace.dart';
import '../settings/settings_workspace.dart';

class OperixDesktopShell extends StatefulWidget {
  const OperixDesktopShell({super.key});

  @override
  State<OperixDesktopShell> createState() => _OperixDesktopShellState();
}

class _OperixDesktopShellState extends State<OperixDesktopShell> {
  OperixModule _selectedModule = OperixModule.dashboard;
  int _businessBadgeReload = 0;
  late final OperixRepository _repository;
  late final DatabaseConfig _databaseConfig;
  late Future<OperixDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _repository = context.read<OperixRepository>();
    _databaseConfig = context.read<DatabaseConfig>();
    _dashboardFuture = _repository.loadDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _repository.loadDashboard();
    });
  }

  Widget _topBar() {
    return FutureBuilder<OperixDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        return _TopBar(
          module: _selectedModule,
          status: snapshot.data?.connectionStatus,
          onRefresh: _refresh,
          onLogout: () => context.read<AppSession>().signOut(),
        );
      },
    );
  }

  Widget _body() {
    if (_selectedModule == OperixModule.pointOfSale) {
      return const PosWorkspace();
    }
    if (_selectedModule == OperixModule.inventory) {
      return const InventoryProductsScreen();
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return OperixDashboard(
          selectedModule: _selectedModule,
          data: snapshot.requireData,
          databaseConfig: _databaseConfig,
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
            selectedModule: _selectedModule,
            businessBadgeReload: _businessBadgeReload,
            onSelected: (module) {
              setState(() => _selectedModule = module);
            },
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedModule,
    required this.businessBadgeReload,
    required this.onSelected,
  });

  final OperixModule selectedModule;
  final int businessBadgeReload;
  final ValueChanged<OperixModule> onSelected;

  static const _items = [
    _NavItem(OperixModule.dashboard, Icons.dashboard_outlined, 'Dashboard'),
    _NavItem(OperixModule.pointOfSale, Icons.point_of_sale, 'POS'),
    _NavItem(OperixModule.sales, Icons.receipt_long, 'Sales'),
    _NavItem(OperixModule.purchases, Icons.shopping_cart_outlined, 'Purchases'),
    _NavItem(OperixModule.inventory, Icons.inventory_2_outlined, 'Inventory'),
    _NavItem(OperixModule.clients, Icons.groups_2_outlined, 'Clients'),
    _NavItem(
      OperixModule.suppliers,
      Icons.local_shipping_outlined,
      'Suppliers',
    ),
    _NavItem(OperixModule.accounting, Icons.account_balance, 'Accounting'),
    _NavItem(OperixModule.settings, Icons.settings_outlined, 'Settings'),
  ];

  String _navLabel(BuildContext context, OperixModule module) {
    final l10n = context.l10n;
    switch (module) {
      case OperixModule.dashboard:
        return l10n.navDashboard;
      case OperixModule.pointOfSale:
        return l10n.navPos;
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
      case OperixModule.accounting:
        return l10n.navAccounting;
      case OperixModule.settings:
        return l10n.navSettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: _BrandHeader(),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = selectedModule == item.module;
                  return Tooltip(
                    message: _navLabel(context, item.module),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: const Color(0xFF172554),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: Icon(
                        item.icon,
                        color: selected
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFFCBD5E1).withAlpha(220),
                      ),
                      title: Text(
                        _navLabel(context, item.module),
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFCBD5E1).withAlpha(230),
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      onTap: () => onSelected(item.module),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _WorkspaceBadge(reloadToken: businessBadgeReload),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Image(
              image: AssetImage('assets/brand/logo.png'),
              semanticLabel: 'Operix logo',
              width: 168,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.businessFinanceDesktop,
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        ),
      ],
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
    return FutureBuilder<BusinessProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile =
            snapshot.data ??
            const BusinessProfile(
              businessName: 'Operix Business',
              branchName: 'Main branch',
            );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2DD4BF).withAlpha(80)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _BusinessAvatar(profile: profile),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.businessName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.branchName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final hasLogo =
        logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync();

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF2DD4BF),
      child: ClipOval(
        child: hasLogo
            ? Image.file(
                File(logoPath),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              )
            : Text(
                profile.initials,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.module,
    required this.status,
    required this.onRefresh,
    required this.onLogout,
  });

  final OperixModule module;
  final DatabaseConnectionStatus? status;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

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
          _StatusPill(status: status),
          const SizedBox(width: 8),
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
      case OperixModule.accounting:
        return l10n.navAccounting;
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
        icon: Icon(
          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DatabaseConnectionStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) {
      const color = Color(0xFF64748B);
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(82)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.connecting,
              style: const TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }
    final connected = status.connected;
    final color = connected ? const Color(0xFF047857) : const Color(0xFFB45309);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.storage : Icons.dataset_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            connected ? context.l10n.postgresql : context.l10n.demoData,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
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
      tooltip: 'Account',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
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

class _NavItem {
  const _NavItem(this.module, this.icon, this.label);

  final OperixModule module;
  final IconData icon;
  final String label;
}
