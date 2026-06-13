import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/l10n_ext.dart';
import '../../app/operix_theme.dart';
import '../../data/auth_repository.dart';
import '../../data/business_repository.dart';
import '../business/business_setup_screen.dart';
import 'login_screen.dart';
import 'setup_screen.dart';

/// Decides the unauthenticated entry point: the first-run setup screen when no
/// users exist yet, otherwise the login screen.
class AuthLanding extends StatefulWidget {
  const AuthLanding({super.key});

  @override
  State<AuthLanding> createState() => _AuthLandingState();
}

class _AuthLandingState extends State<AuthLanding> {
  late Future<_AuthEntryState> _entryState;

  @override
  void initState() {
    super.initState();
    _entryState = _loadEntryState();
  }

  void _retry() {
    setState(() {
      _entryState = _loadEntryState();
    });
  }

  Future<_AuthEntryState> _loadEntryState() async {
    final businessRepository = context.read<BusinessRepository>();
    final authRepository = context.read<AuthRepository>();

    final hasBusiness = await businessRepository.hasProfile();
    if (!hasBusiness) {
      return const _AuthEntryState(hasBusiness: false, hasUsers: false);
    }

    final hasUsers = await authRepository.hasUsers();
    return _AuthEntryState(hasBusiness: true, hasUsers: hasUsers);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthEntryState>(
      future: _entryState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: OperixColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _ConnectionError(
            message: '${snapshot.error}',
            onRetry: _retry,
          );
        }
        final state = snapshot.requireData;
        if (!state.hasBusiness) {
          return BusinessSetupScreen(onSaved: _retry);
        }
        return state.hasUsers ? const LoginScreen() : const SetupScreen();
      },
    );
  }
}

class _AuthEntryState {
  const _AuthEntryState({required this.hasBusiness, required this.hasUsers});

  final bool hasBusiness;
  final bool hasUsers;
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OperixColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 44,
                    color: OperixColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.cannotReachDatabase,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: OperixColors.muted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
