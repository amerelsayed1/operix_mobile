import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../data/license_repository.dart';
import '../domain/license_models.dart';
import '../features/auth/auth_landing.dart';
import '../features/license/license_screen.dart';
import '../features/shell/operix_desktop_shell.dart';
import 'app_session.dart';
import 'locale_controller.dart';
import 'operix_theme.dart';

class OperixApp extends StatelessWidget {
  const OperixApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    );

    final locale = context.watch<LocaleController>().locale;

    return MaterialApp(
      title: 'Operix Desktop',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Arial',
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFF0F172A),
          selectedIconTheme: const IconThemeData(color: Color(0xFF2DD4BF)),
          selectedLabelTextStyle: const TextStyle(
            color: Color(0xFFE0F2FE),
            fontWeight: FontWeight.w700,
          ),
          unselectedIconTheme: IconThemeData(
            color: const Color(0xFFCBD5E1).withAlpha(210),
          ),
          unselectedLabelTextStyle: TextStyle(
            color: const Color(0xFFCBD5E1).withAlpha(210),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        dataTableTheme: const DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(Color(0xFFF1F5F9)),
          dividerThickness: 0.6,
        ),
      ),
      home: const _LicenseGate(),
    );
  }
}

class _LicenseGate extends StatefulWidget {
  const _LicenseGate();

  @override
  State<_LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<_LicenseGate> {
  late Future<LicenseValidationResult> _licenseFuture;

  @override
  void initState() {
    super.initState();
    _licenseFuture = context.read<LicenseRepository>().loadLicense();
  }

  void _reloadLicense() {
    setState(() {
      _licenseFuture = context.read<LicenseRepository>().loadLicense();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LicenseValidationResult>(
      future: _licenseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: OperixColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return LicenseScreen(
            initialResult: LicenseValidationResult(
              status: LicenseStatus.invalid,
              message: 'License validation failed: ${snapshot.error}',
              installationId: 'Unavailable',
            ),
            onActivated: _reloadLicense,
          );
        }

        final result = snapshot.requireData;
        if (!result.isValid) {
          return LicenseScreen(
            initialResult: result,
            onActivated: _reloadLicense,
          );
        }

        return const _AuthGate();
      },
    );
  }
}

/// Shows the login screen until a user is authenticated, then the desktop shell.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authenticated = context.select<AppSession, bool>(
      (s) => s.isAuthenticated,
    );
    if (!authenticated) {
      return const AuthLanding();
    }
    return const OperixDesktopShell();
  }
}
