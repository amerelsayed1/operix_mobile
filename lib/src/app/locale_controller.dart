import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists the selected UI language (English / Arabic).
class LocaleController extends ChangeNotifier {
  LocaleController([Locale initial = const Locale('en')]) : _locale = initial;

  static const String _prefsKey = 'operix_locale';
  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  Locale _locale;
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  /// Loads the saved locale (defaults to English) before the app starts.
  static Future<LocaleController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      return LocaleController(code == 'ar' ? const Locale('ar') : const Locale('en'));
    } catch (_) {
      return LocaleController();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (_) {
      // Non-fatal: language still applies for this session.
    }
  }

  Future<void> toggle() =>
      setLocale(isArabic ? const Locale('en') : const Locale('ar'));
}
