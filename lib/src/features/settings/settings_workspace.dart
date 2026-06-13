import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/operix_theme.dart';
import '../../config/database_config.dart';
import '../../data/business_repository.dart';
import '../../domain/business_profile.dart';
import '../../domain/license_models.dart';
import '../../domain/operix_models.dart';
import '../../data/license_repository.dart';

enum _SettingsSection {
  company,
  documents,
  payments,
  products,
  accounting,
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
  _SettingsSection _section = _SettingsSection.company;
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

  Future<void> _profileSaved() async {
    widget.onBusinessChanged?.call();
    setState(_reload);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: OperixColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: _SettingsNav(
              selected: _section,
              onSelected: (section) => setState(() => _section = section),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _sectionBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBody() {
    switch (_section) {
      case _SettingsSection.company:
        return FutureBuilder<BusinessProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile =
                snapshot.data ??
                const BusinessProfile(
                  businessName: 'Operix Business',
                  branchName: 'Main branch',
                );
            return _CompanySettingsPanel(
              profile: profile,
              onSaved: _profileSaved,
            );
          },
        );
      case _SettingsSection.documents:
        return const _PlannedSettingsPanel(
          title: 'Documents & printing',
          description:
              'Matches Operix web settings for receipts, invoices, barcode labels, and printer templates.',
          items: [
            _ReviewedItem(
              'Cashier receipt template',
              'Local receipt header, logo, footer, paper width',
            ),
            _ReviewedItem(
              'Invoice print layouts',
              'Sales and supplier invoice configuration',
            ),
            _ReviewedItem(
              'Printer profiles',
              'Thermal receipt, barcode label, and document printers',
            ),
          ],
        );
      case _SettingsSection.payments:
        return const _PlannedSettingsPanel(
          title: 'Payment methods',
          description:
              'The web app supports cash, bank, wallet, card, and custom methods with account mapping.',
          items: [
            _ReviewedItem('Cash', 'Default drawer/cash account mapping'),
            _ReviewedItem(
              'Card / bank',
              'Reference number and settlement account support',
            ),
            _ReviewedItem(
              'Wallet / custom',
              'Named local methods for POS split payments',
            ),
          ],
        );
      case _SettingsSection.products:
        return const _PlannedSettingsPanel(
          title: 'Products reference data',
          description:
              'The web app Settings area contains categories, attributes, units, taxes, and tax groups.',
          items: [
            _ReviewedItem(
              'Categories',
              'Product grouping for POS and inventory',
            ),
            _ReviewedItem('Units', 'Piece, box, kg, meter, and custom units'),
            _ReviewedItem(
              'Taxes',
              'Tax rates and default POS/sales tax behavior',
            ),
          ],
        );
      case _SettingsSection.accounting:
        return const _PlannedSettingsPanel(
          title: 'Accounting & compliance',
          description:
              'Local desktop should keep only operational accounting settings, not SaaS tenant governance.',
          items: [
            _ReviewedItem(
              'Fiscal periods',
              'Open/close/reopen local accounting periods',
            ),
            _ReviewedItem(
              'Posting controls',
              'Sales, purchases, inventory adjustments, cash variance',
            ),
            _ReviewedItem(
              'Compliance',
              'Egypt ETA / tax identifiers when needed by the client',
            ),
          ],
        );
      case _SettingsSection.system:
        return _SystemSettingsPanel(
          status: widget.status,
          databaseConfig: widget.databaseConfig,
          licenseFuture: _licenseFuture,
        );
    }
  }
}

class _SettingsNav extends StatelessWidget {
  const _SettingsNav({required this.selected, required this.onSelected});

  final _SettingsSection selected;
  final ValueChanged<_SettingsSection> onSelected;

  static const _items = [
    _SettingsNavItem(
      _SettingsSection.company,
      Icons.storefront_outlined,
      'Company',
    ),
    _SettingsNavItem(
      _SettingsSection.documents,
      Icons.print_outlined,
      'Documents',
    ),
    _SettingsNavItem(_SettingsSection.payments, Icons.credit_card, 'Payments'),
    _SettingsNavItem(
      _SettingsSection.products,
      Icons.category_outlined,
      'Products',
    ),
    _SettingsNavItem(
      _SettingsSection.accounting,
      Icons.account_balance,
      'Accounting',
    ),
    _SettingsNavItem(_SettingsSection.system, Icons.storage_outlined, 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: OperixColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Local business configuration',
            style: TextStyle(color: OperixColors.muted),
          ),
          const SizedBox(height: 18),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selected == item.section,
                selectedTileColor: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: Icon(item.icon),
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () => onSelected(item.section),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanySettingsPanel extends StatefulWidget {
  const _CompanySettingsPanel({required this.profile, required this.onSaved});

  final BusinessProfile profile;
  final VoidCallback onSaved;

  @override
  State<_CompanySettingsPanel> createState() => _CompanySettingsPanelState();
}

class _CompanySettingsPanelState extends State<_CompanySettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _branchController;
  late final TextEditingController _logoController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.businessName);
    _branchController = TextEditingController(text: widget.profile.branchName);
    _logoController = TextEditingController(
      text: widget.profile.logoPath ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<BusinessRepository>().saveProfile(
        BusinessProfile(
          businessName: _nameController.text,
          branchName: _branchController.text,
          logoPath: _logoController.text,
        ),
      );
      if (!mounted) return;
      widget.onSaved();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Company information',
      subtitle:
          'Reviewed from Operix web Company Settings. Billing/subscription fields are intentionally excluded for local desktop.',
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LogoPreview(
              businessName: _nameController.text,
              logoPath: _logoController.text,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business name',
                      prefixIcon: Icon(Icons.storefront_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter the business name'
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _branchController,
                    decoration: const InputDecoration(
                      labelText: 'Branch name',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter the branch name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _logoController,
                    decoration: const InputDecoration(
                      labelText: 'Business logo path',
                      hintText: '/Users/.../logo.png',
                      prefixIcon: Icon(Icons.image_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
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
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Saving…' : 'Save company settings',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedSettingsPanel extends StatelessWidget {
  const _PlannedSettingsPanel({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<_ReviewedItem> items;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: title,
      subtitle: description,
      child: Column(
        children: [
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.check_circle_outline,
                color: OperixColors.tealDark,
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(item.description),
              trailing: const _StatusChip(label: 'Planned'),
            ),
        ],
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
    return Column(
      children: [
        _SettingsCard(
          title: 'Database',
          subtitle: 'Local PostgreSQL connection used by this workstation.',
          child: Column(
            children: [
              _SettingLine(
                'Source',
                status.connected ? 'PostgreSQL' : 'Demo data',
              ),
              _SettingLine('Target', databaseConfig.targetLabel),
              _SettingLine(
                'Configured',
                databaseConfig.isConfigured ? 'Yes' : 'No',
              ),
              _SettingLine('SSL mode', databaseConfig.sslModeName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<LicenseValidationResult>(
          future: licenseFuture,
          builder: (context, snapshot) {
            final result = snapshot.data;
            final license = result?.license;
            return _SettingsCard(
              title: 'License',
              subtitle: 'Offline workstation activation.',
              child: Column(
                children: [
                  _SettingLine(
                    'Installation id',
                    result?.installationId ?? 'Loading…',
                  ),
                  _SettingLine('Status', result?.status.name ?? 'Loading'),
                  _SettingLine(
                    'Licensed business',
                    license?.businessName ?? '—',
                  ),
                  _SettingLine(
                    'Expires',
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: OperixColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: OperixColors.muted)),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.businessName, required this.logoPath});

  final String businessName;
  final String logoPath;

  @override
  Widget build(BuildContext context) {
    final path = logoPath.trim();
    final hasLogo = path.isNotEmpty && File(path).existsSync();
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: OperixColors.night,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OperixColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.file(File(path), fit: BoxFit.cover)
          : Center(
              child: Text(
                BusinessProfile(
                  businessName: businessName,
                  branchName: '',
                ).initials,
                style: const TextStyle(
                  color: OperixColors.teal,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: OperixColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OperixColors.warning.withAlpha(70)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: OperixColors.warning,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingsNavItem {
  const _SettingsNavItem(this.section, this.icon, this.label);

  final _SettingsSection section;
  final IconData icon;
  final String label;
}

class _ReviewedItem {
  const _ReviewedItem(this.title, this.description);

  final String title;
  final String description;
}
