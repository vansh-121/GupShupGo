import 'package:flutter/material.dart';
import 'package:video_chat_app/main.dart';

/// Persists the user's preferred [ThemeMode] across app restarts.
/// Uses the globally initialised [sharedPrefs] from main.dart.
class ThemeProvider extends ChangeNotifier {
  static const _kThemeMode = 'pref_theme_mode';

  ThemeMode get themeMode {
    final val = sharedPrefs.getInt(_kThemeMode) ?? ThemeMode.system.index;
    return ThemeMode.values[val.clamp(0, ThemeMode.values.length - 1)];
  }

  void setThemeMode(ThemeMode mode) {
    sharedPrefs.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  bool isDark(BuildContext context) {
    if (themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return themeMode == ThemeMode.dark;
  }
}
