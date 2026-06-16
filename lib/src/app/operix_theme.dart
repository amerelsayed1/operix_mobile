import 'package:flutter/material.dart';

import '../domain/value_objects/money.dart';

const String kOperixFontFamily = 'Tahoma';

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

/// App-wide currency formatting helper (double input). Prefer [formatMoney] for
/// money that originates from a [Money] value; this overload remains for interim
/// double values (e.g. live text-field input in the payment dialog).
String formatEgp(double value) {
  final negative = value < 0;
  final absVal = value.abs();
  final whole = absVal.truncate();
  final fraction = ((absVal - whole) * 100).round().toString().padLeft(2, '0');
  return _composeEgp(negative, whole.toString(), fraction);
}

/// App-wide currency formatting helper for [Money]. Formats from the exact
/// 2-decimal storage string so no floating point is involved.
String formatMoney(Money value) {
  final text = value.toStorageString(); // e.g. "-1234.50"
  final negative = text.startsWith('-');
  final unsigned = negative ? text.substring(1) : text;
  final dot = unsigned.indexOf('.');
  final whole = dot >= 0 ? unsigned.substring(0, dot) : unsigned;
  final fraction = dot >= 0 ? unsigned.substring(dot + 1) : '00';
  return _composeEgp(negative, whole, fraction);
}

String _composeEgp(bool negative, String whole, String fraction) {
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[i]);
  }
  return '${negative ? '-' : ''}EGP $buffer.$fraction';
}
