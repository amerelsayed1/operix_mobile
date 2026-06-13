import 'package:flutter/material.dart';

/// Shared palette so the POS / auth screens match the existing desktop shell.
class OperixColors {
  const OperixColors._();

  static const Color night = Color(0xFF0F172A);
  static const Color nightTile = Color(0xFF172554);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color ink = Color(0xFF182521);
  static const Color muted = Color(0xFF66756F);
  static const Color subtle = Color(0xFFCBD5E1);
  static const Color success = Color(0xFF047857);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFBE123C);
}

/// App-wide currency formatting helper.
String formatEgp(double value) {
  final negative = value < 0;
  final absVal = value.abs();
  final whole = absVal.truncate();
  final fraction = ((absVal - whole) * 100).round().toString().padLeft(2, '0');
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}EGP $buffer.$fraction';
}
