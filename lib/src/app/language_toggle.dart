import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'locale_controller.dart';

/// Toggles the UI language between English and Arabic. The label shows the
/// language you would switch TO.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({this.onDark = false, super.key});

  /// Use light foreground colors when placed on a dark background.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final color = onDark ? Colors.white : const Color(0xFF334155);
    final nextLabel = controller.isArabic ? 'English' : 'العربية';
    return TextButton.icon(
      onPressed: () => controller.toggle(),
      style: TextButton.styleFrom(foregroundColor: color),
      icon: const Icon(Icons.translate, size: 18),
      label: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
