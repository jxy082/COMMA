import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // The default is System Theme Mode
  SharedPreferences? _prefs;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    final themeModeString = _prefs?.getString('themeMode') ?? 'system';
    _themeMode = _stringToThemeMode(themeModeString);
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setString('themeMode', _themeModeToString(_themeMode));
  }

  ThemeMode _stringToThemeMode(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
