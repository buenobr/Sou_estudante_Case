import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode');

    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    await prefs.setString('themeMode', themeModeString);
    notifyListeners();
  }
}