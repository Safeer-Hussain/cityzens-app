import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeProvider(this._prefs)
      : _themeMode = _loadSavedThemeMode(_prefs);

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static ThemeMode _loadSavedThemeMode(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.dark;
    final saved = prefs.getString(_prefKey);
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark; // Default to sleek executive dark
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    if (_prefs != null) {
      await _prefs.setString(
        _prefKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    if (_prefs != null) {
      await _prefs.setString(
        _prefKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    }
  }
}
