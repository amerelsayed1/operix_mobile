import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/operix_theme.dart';
import '../../data/license_repository.dart';
import '../../domain/license_models.dart';
import '../auth/auth_widgets.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({
    required this.initialResult,
    required this.onActivated,
    super.key,
  });

  final LicenseValidationResult initialResult;
  final VoidCallback onActivated;

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _licenseController = TextEditingController();

  late LicenseValidationResult _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;
  }

  @override
  void didUpdateWidget(covariant LicenseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialResult != widget.initialResult) {
      _result = widget.initialResult;
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_submitting) return;
    final licenseKey = _licenseController.text.trim();
    if (licenseKey.isEmpty) {
      setState(() {
        _result = LicenseValidationResult(
          status: LicenseStatus.invalid,
          message: 'Paste the license key for this workstation.',
          installationId: _result.installationId,
        );
      });
      return;
    }

    setState(() => _submitting = true);
    final result = await context.read<LicenseRepository>().activate(licenseKey);
    if (!mounted) return;

    setState(() {
      _submitting = false;
      _result = result;
    });

    if (result.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      widget.onActivated();
    }
  }

  Future<void> _copyInstallationId() async {
    await Clipboard.setData(ClipboardData(text: _result.installationId));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Installation id copied')));
  }

  @override
  Widget build(BuildContext context) {
    final invalid = _result.status != LicenseStatus.missing;

    return AuthScaffold(
      brand: const AuthBrandPanel(
        headline: 'Activate Operix Desktop',
        subtitle:
            'Each local workstation uses a signed offline license before '
            'the business database, users, and POS terminal are opened.',
      ),
      form: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'License required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: OperixColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _result.message,
              style: TextStyle(
                color: invalid ? OperixColors.danger : OperixColors.muted,
                fontWeight: invalid ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Installation id',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: OperixColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OperixColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _result.installationId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Copy installation id',
                    child: IconButton(
                      onPressed: _copyInstallationId,
                      icon: const Icon(Icons.copy),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _licenseController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'License key',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.verified_user_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _activate,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.key),
                label: Text(_submitting ? 'Validating…' : 'Activate license'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
