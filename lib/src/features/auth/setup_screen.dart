import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_session.dart';
import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/auth_repository.dart';
import 'auth_widgets.dart';

/// First-run screen shown when no user accounts exist yet. Creates the initial
/// administrator account, then signs in.
class SetupScreen extends StatefulWidget {
  const SetupScreen({this.onCreated, super.key});

  /// Called after the admin is created (e.g. so the gate can re-evaluate).
  final VoidCallback? onCreated;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final user = await context.read<AuthRepository>().createFirstAdmin(
            username: _usernameController.text,
            fullName: _fullNameController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      widget.onCreated?.call();
      context.read<AppSession>().signIn(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.unexpectedError('$e'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      brand: AuthBrandPanel(
        headline: l10n.setupHeadline,
        subtitle: l10n.setupSubtitle,
      ),
      form: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.setupTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: OperixColors.ink,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.setupHint,
                style: const TextStyle(color: OperixColors.muted),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? l10n.enterFullName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.chooseUsername;
                  if (value.trim().length < 3) return l10n.usernameMinChars;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? l10n.show : l10n.hide,
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.choosePassword;
                  if (value.length < 6) return l10n.passwordMinChars;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value != _passwordController.text ? l10n.passwordsDontMatch : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.person_add_alt),
                  label: Text(_submitting ? l10n.creating : l10n.createAccountContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
