import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../config/database_config.dart';
import '../../data/business_repository.dart';
import '../../data/license_repository.dart';
import '../../domain/business_profile.dart';
import '../../domain/license_models.dart';
import '../../domain/operix_models.dart';
import 'categories_panel.dart';
import 'company_settings_panel.dart';
import 'roles_permissions_panel.dart';
import 'settings_ui.dart';
import 'units_panel.dart';

enum SettingsSection {
  company,
  accounting,
  roles,
  payments,
  costCategories,
  invoiceSettings,
  printSettings,
  printers,
  posDevices,
  itemCategories,
  itemAttributes,
  units,
  taxSettings,
  system,
}

class SettingsWorkspace extends StatefulWidget {
  const SettingsWorkspace({
    required this.status,
    required this.databaseConfig,
    this.onBusinessChanged,
    super.key,
  });

  final DatabaseConnectionStatus status;
  final DatabaseConfig databaseConfig;
  final VoidCallback? onBusinessChanged;

  @override
  State<SettingsWorkspace> createState() => _SettingsWorkspaceState();
}

class _SettingsWorkspaceState extends State<SettingsWorkspace> {
  SettingsSection _section = SettingsSection.company;
  late Future<BusinessProfile?> _profileFuture;
  late Future<LicenseValidationResult> _licenseFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _profileFuture = context.read<BusinessRepository>().loadProfile();
    _licenseFuture = context.read<LicenseRepository>().loadLicense();
  }

  void _profileSaved() {
    widget.onBusinessChanged?.call();
    setState(_reload);
  }

  String _sectionLabel(SettingsSection section) {
    final l10n = context.l10n;
    return switch (section) {
      SettingsSection.company => l10n.navCompanyInfo,
      SettingsSection.accounting => l10n.navAccountingSettings,
      SettingsSection.roles => l10n.navRolesPermissions,
      SettingsSection.payments => l10n.navPaymentMethods,
      SettingsSection.costCategories => l10n.navCostCategories,
      SettingsSection.invoiceSettings => l10n.navInvoiceSettings,
      SettingsSection.printSettings => l10n.navPrintSettings,
      SettingsSection.printers => l10n.navPrinters,
      SettingsSection.posDevices => l10n.navPosDevices,
      SettingsSection.itemCategories => l10n.navItemCategories,
      SettingsSection.itemAttributes => l10n.navItemAttributes,
      SettingsSection.units => l10n.navUnits,
      SettingsSection.taxSettings => l10n.navTaxSettings,
      SettingsSection.system => l10n.navSettings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: OperixColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 22, 40, 0),
            child: SettingsBreadcrumb(
              trail: [
                l10n.navDashboard,
                l10n.navSettings,
                _sectionLabel(_section),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 24, 24, 40),
                    child: _sectionBody(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                  child: _SettingsNav(
                    selected: _section,
                    onSelected: (s) => setState(() => _section = s),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody() {
    switch (_section) {
      case SettingsSection.company:
        return FutureBuilder<BusinessProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile =
                snapshot.data ??
                const BusinessProfile(
                  businessName: '',
                  branchName: 'Main branch',
                );
            return CompanySettingsPanel(
              key: ValueKey(profile.hashCode),
              profile: profile,
              onSaved: _profileSaved,
            );
          },
        );
      case SettingsSection.roles:
        if (!context.read<AppSession>().can('roles.view')) {
          return const _RestrictedPanel();
        }
        return const RolesPermissionsPanel();
      case SettingsSection.itemCategories:
        return const CategoriesPanel();
      case SettingsSection.units:
        return const UnitsPanel();
      case SettingsSection.system:
        return _SystemSettingsPanel(
          status: widget.status,
          databaseConfig: widget.databaseConfig,
          licenseFuture: _licenseFuture,
        );
      default:
        return _ComingSoonPanel(title: _sectionLabel(_section));
    }
  }
}

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({required this.selected, required this.onSelected});

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canViewRoles = context.read<AppSession>().can('roles.view');
    final groups = <_NavGroup>[
      _NavGroup(l10n.settingsGroupBusiness, [
        const _NavItem(SettingsSection.company, Icons.business_outlined),
        const _NavItem(SettingsSection.accounting, Icons.menu_book_outlined),
        if (canViewRoles)
          const _NavItem(SettingsSection.roles, Icons.shield_outlined),
        const _NavItem(SettingsSection.payments, Icons.credit_card_outlined),
        const _NavItem(SettingsSection.costCategories, Icons.sell_outlined),
      ]),
      _NavGroup(l10n.settingsGroupDocuments, const [
        _NavItem(SettingsSection.invoiceSettings, Icons.description_outlined),
        _NavItem(SettingsSection.printSettings, Icons.print_outlined),
        _NavItem(SettingsSection.printers, Icons.local_printshop_outlined),
      ]),
      _NavGroup(l10n.settingsGroupPos, const [
        _NavItem(SettingsSection.posDevices, Icons.desktop_windows_outlined),
      ]),
      _NavGroup(l10n.settingsGroupProducts, const [
        _NavItem(SettingsSection.itemCategories, Icons.account_tree_outlined),
        _NavItem(SettingsSection.itemAttributes, Icons.label_outline),
        _NavItem(SettingsSection.units, Icons.straighten_outlined),
        _NavItem(SettingsSection.taxSettings, Icons.percent_outlined),
      ]),
      _NavGroup(l10n.navSettings, const [
        _NavItem(SettingsSection.system, Icons.storage_outlined),
      ]),
    ];

    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OperixColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var g = 0; g < groups.length; g++) ...[
              if (g > 0) const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  groups[g].title,
                  style: const TextStyle(
                    color: OperixColors.subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              for (final item in groups[g].items)
                _NavTile(
                  label: _label(context, item.section),
                  icon: item.icon,
                  selected: selected == item.section,
                  onTap: () => onSelected(item.section),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _label(BuildContext context, SettingsSection section) {
    final l10n = context.l10n;
    return switch (section) {
      SettingsSection.company => l10n.navCompanyInfo,
      SettingsSection.accounting => l10n.navAccountingSettings,
      SettingsSection.roles => l10n.navRolesPermissions,
      SettingsSection.payments => l10n.navPaymentMethods,
      SettingsSection.costCategories => l10n.navCostCategories,
      SettingsSection.invoiceSettings => l10n.navInvoiceSettings,
      SettingsSection.printSettings => l10n.navPrintSettings,
      SettingsSection.printers => l10n.navPrinters,
      SettingsSection.posDevices => l10n.navPosDevices,
      SettingsSection.itemCategories => l10n.navItemCategories,
      SettingsSection.itemAttributes => l10n.navItemAttributes,
      SettingsSection.units => l10n.navUnits,
      SettingsSection.taxSettings => l10n.navTaxSettings,
      SettingsSection.system => l10n.navSettings,
    };
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF4F46E5) : const Color(0xFF475569);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Material(
        color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? color : const Color(0xFF334155),
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavGroup {
  const _NavGroup(this.title, this.items);
  final String title;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.section, this.icon);
  final SettingsSection section;
  final IconData icon;
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsCard(
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 44,
              color: OperixColors.subtle,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.comingSoonTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: OperixColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.comingSoonBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: OperixColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictedPanel extends StatelessWidget {
  const _RestrictedPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsCard(
      title: l10n.accessDeniedTitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 44,
              color: OperixColors.subtle,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.accessDeniedBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: OperixColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemSettingsPanel extends StatelessWidget {
  const _SystemSettingsPanel({
    required this.status,
    required this.databaseConfig,
    required this.licenseFuture,
  });

  final DatabaseConnectionStatus status;
  final DatabaseConfig databaseConfig;
  final Future<LicenseValidationResult> licenseFuture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          title: l10n.settingsDatabase,
          subtitle: l10n.settingsDatabaseSubtitle,
          child: Column(
            children: [
              _SettingLine(
                l10n.settingsSource,
                status.connected ? 'PostgreSQL' : l10n.settingsDemoData,
              ),
              _SettingLine(l10n.settingsTarget, databaseConfig.targetLabel),
              _SettingLine(
                l10n.settingsConfigured,
                databaseConfig.isConfigured
                    ? l10n.settingsYes
                    : l10n.settingsNo,
              ),
              _SettingLine(l10n.settingsSslMode, databaseConfig.sslModeName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<LicenseValidationResult>(
          future: licenseFuture,
          builder: (context, snapshot) {
            final result = snapshot.data;
            final license = result?.license;
            return SettingsCard(
              title: l10n.settingsLicense,
              subtitle: l10n.settingsLicenseSubtitle,
              child: Column(
                children: [
                  _SettingLine(
                    l10n.settingsInstallationId,
                    result?.installationId ?? l10n.settingsLoading,
                  ),
                  _SettingLine(
                    l10n.settingsStatus,
                    result?.status.name ?? l10n.settingsLoading,
                  ),
                  _SettingLine(
                    l10n.settingsLicensedBusiness,
                    license?.businessName ?? '—',
                  ),
                  _SettingLine(
                    l10n.settingsExpires,
                    license?.expiresAt.toLocal().toString() ?? '—',
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingLine extends StatelessWidget {
  const _SettingLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: OperixColors.muted),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
