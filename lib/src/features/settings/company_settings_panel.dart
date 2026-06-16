import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/business_repository.dart';
import '../../domain/business_profile.dart';
import 'settings_ui.dart';

/// Pragmatic email shape check (non-empty local part, domain with a dot).
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Settings → Company information. Mirrors the Operix web "معلومات الشركة" form:
/// logo, contact details, registration and address in a two-column grid.
class CompanySettingsPanel extends StatefulWidget {
  const CompanySettingsPanel({
    required this.profile,
    required this.onSaved,
    super.key,
  });

  final BusinessProfile profile;
  final VoidCallback onSaved;

  @override
  State<CompanySettingsPanel> createState() => _CompanySettingsPanelState();
}

class _CompanySettingsPanelState extends State<CompanySettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _commercialReg;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _country;
  late final TextEditingController _postal;
  late final TextEditingController _address;
  String _logoPath = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p.businessName);
    _email = TextEditingController(text: p.email ?? '');
    _phone = TextEditingController(text: p.phone ?? '');
    _commercialReg = TextEditingController(
      text: p.commercialRegistration ?? '',
    );
    _city = TextEditingController(text: p.city ?? '');
    _region = TextEditingController(text: p.region ?? '');
    _country = TextEditingController(text: p.country ?? '');
    _postal = TextEditingController(text: p.postalCode ?? '');
    _address = TextEditingController(text: p.address ?? '');
    _logoPath = p.logoPath ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _commercialReg,
      _city,
      _region,
      _country,
      _postal,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<BusinessRepository>().saveProfile(
        widget.profile.copyWith(
          businessName: _name.text.trim(),
          logoPath: _logoPath.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          commercialRegistration: _commercialReg.text.trim(),
          city: _city.text.trim(),
          region: _region.text.trim(),
          country: _country.text.trim(),
          postalCode: _postal.text.trim(),
          address: _address.text.trim(),
        ),
      );
      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.companySettingsSaved)),
      );
    } catch (e) {
      // Surface save failures instead of silently stopping the spinner.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unexpectedError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editLogo() async {
    final controller = TextEditingController(text: _logoPath);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logoPathDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '/Users/.../logo.png',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.saveChanges),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) setState(() => _logoPath = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsCard(
      title: l10n.navCompanyInfo,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _logoSection(l10n),
            const SizedBox(height: 24),
            _row(
              LabeledField(
                label: l10n.companySettingsNameLabel,
                required: true,
                controller: _name,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.companySettingsNameRequired
                    : null,
              ),
              LabeledField(
                label: l10n.emailLabel,
                required: true,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return l10n.emailRequired;
                  if (!_emailPattern.hasMatch(text)) return l10n.emailInvalid;
                  return null;
                },
              ),
            ),
            _row(
              _phoneField(l10n),
              LabeledField(
                label: l10n.commercialRegLabel,
                controller: _commercialReg,
                hint: l10n.commercialRegHint,
              ),
            ),
            _row(
              LabeledField(label: l10n.cityLabel, controller: _city),
              LabeledField(label: l10n.regionLabel, controller: _region),
            ),
            _row(
              LabeledField(label: l10n.countryLabel, controller: _country),
              LabeledField(
                label: l10n.postalCodeLabel,
                controller: _postal,
                hint: l10n.postalCodeHint,
              ),
            ),
            LabeledField(
              label: l10n.addressLabel,
              controller: _address,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: OperixColors.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.saveChanges),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.businessLogoLabel, style: kFieldLabelStyle),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LogoBox(
              businessName: _name.text,
              logoPath: _logoPath,
              onTap: _editLogo,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.logoUploadHint,
                style: const TextStyle(
                  color: OperixColors.muted,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _phoneField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.phoneFieldLabel, style: kFieldLabelStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: kFieldDecoration(null),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OperixColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇪🇬', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    widget.profile.phoneCountryCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: OperixColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(Widget start, Widget end) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: start),
          const SizedBox(width: 20),
          Expanded(child: end),
        ],
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox({
    required this.businessName,
    required this.logoPath,
    required this.onTap,
  });

  final String businessName;
  final String logoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final path = logoPath.trim();
    final placeholder = Center(
      child: Text(
        BusinessProfile(
          businessName: businessName.isEmpty ? 'OP' : businessName,
          branchName: '',
        ).initials,
        style: const TextStyle(
          color: OperixColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OperixColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        // No synchronous existsSync() in build: Image.file loads off the UI
        // thread and errorBuilder covers a missing/invalid path.
        child: path.isEmpty
            ? placeholder
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
