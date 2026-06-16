import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/business_repository.dart';
import '../../data/license_repository.dart';
import '../../domain/business_profile.dart';
import '../auth/auth_widgets.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({required this.onSaved, super.key});

  final VoidCallback onSaved;

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _branchNameController = TextEditingController(text: 'Main branch');
  final _logoPathController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillFromLicense();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _branchNameController.dispose();
    _logoPathController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromLicense() async {
    final result = await context.read<LicenseRepository>().loadLicense();
    if (!mounted || !result.isValid) return;
    final name = result.license?.businessName.trim();
    if (name != null &&
        name.isNotEmpty &&
        _businessNameController.text.trim().isEmpty) {
      _businessNameController.text = name;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await context.read<BusinessRepository>().saveProfile(
        BusinessProfile(
          businessName: _businessNameController.text,
          branchName: _branchNameController.text,
          logoPath: _logoPathController.text,
        ),
      );
      if (!mounted) return;
      widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = context.l10n.onbSaveError('$error'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      brand: AuthBrandPanel(
        headline: context.l10n.onbBusinessHeadline,
        subtitle: context.l10n.onbBusinessSubtitle,
      ),
      form: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.onbBusinessIdentity,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: OperixColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.onbBusinessIdentityHint,
                style: const TextStyle(color: OperixColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LogoPreview(
                    businessName: _businessNameController.text,
                    logoPath: _logoPathController.text,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _businessNameController,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.l10n.onbBusinessNameLabel,
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? context.l10n.onbBusinessNameRequired
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _branchNameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.l10n.onbBranchNameLabel,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? context.l10n.onbBranchNameRequired
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logoPathController,
                decoration: InputDecoration(
                  labelText: context.l10n.onbLogoPathLabel,
                  hintText: '/Users/.../logo.png',
                  prefixIcon: const Icon(Icons.image_outlined),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.onbLogoPathOptional,
                style: const TextStyle(color: OperixColors.muted, fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
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
                      : const Icon(Icons.check),
                  label: Text(
                    _saving
                        ? context.l10n.onbSaving
                        : context.l10n.onbSaveBusiness,
                  ),
                ),
              ),
            ],
          ),
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
    final placeholder = Center(
      child: Text(
        _initials,
        style: const TextStyle(
          color: OperixColors.teal,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: OperixColors.night,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OperixColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      // No synchronous existsSync() in build: Image.file loads off the UI thread
      // and errorBuilder covers a missing/invalid path.
      child: path.isEmpty
          ? placeholder
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }

  String get _initials {
    final parts = businessName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'OP';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
