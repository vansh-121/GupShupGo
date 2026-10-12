import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';

/// Persists the user's chosen app language across restarts, using the globally
/// initialised [sharedPrefs] from main.dart (same pattern as ThemeProvider).
///
/// A null [locale] means "follow the device language" — the default — in which
/// case MaterialApp resolves against `supportedLocales` on its own. A non-null
/// value is an explicit in-app override chosen from Settings → Language.
///
/// Only the language code is stored (e.g. `hi`, `ar`); all currently supported
/// locales are language-only, so there is no country subtag to preserve.
class LocaleProvider extends ChangeNotifier {
  static const _kLocale = 'app_locale';

  /// The override locale, or null to follow the system language.
  Locale? get locale {
    final code = sharedPrefs.getString(_kLocale);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  /// True when no explicit language is set (following the device).
  bool get isSystem => locale == null;

  /// Sets the app language. Pass null to clear the override and follow the
  /// device language again.
  void setLocale(Locale? locale) {
    if (locale == null) {
      sharedPrefs.remove(_kLocale);
    } else {
      sharedPrefs.setString(_kLocale, locale.languageCode);
    }
    notifyListeners();
  }
}
