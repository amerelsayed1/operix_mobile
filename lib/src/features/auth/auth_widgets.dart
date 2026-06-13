import 'package:flutter/material.dart';

import '../../app/language_toggle.dart';
import '../../app/operix_theme.dart';

/// Dark brand panel shown beside the login / setup forms.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({
    required this.headline,
    required this.subtitle,
    super.key,
  });

  final String headline;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OperixColors.night,
      padding: const EdgeInsets.all(36),
      child: Column(
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
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Spacer(),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: OperixColors.subtle, height: 1.5),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OperixColors.danger.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OperixColors.danger.withAlpha(70)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: OperixColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: OperixColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outer card + two-pane layout shared by login and setup screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.brand, required this.form, super.key});

  final Widget brand;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OperixColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880, maxHeight: 580),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(flex: 5, child: brand),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 40,
                        ),
                        child: form,
                      ),
                    ),
                  ],
                ),
                const PositionedDirectional(
                  top: 6,
                  end: 10,
                  child: LanguageToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
