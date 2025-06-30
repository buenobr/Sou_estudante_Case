// =================================================================================
// ARQUIVO: lib/theme_manager.dart (CORRIGIDO INÍCIO NO TEMA CLARO)
// =================================================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Padrão inicial, mas será sobrescrito ao carregar

  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadThemeMode();
  }

  // Carrega a preferência de tema do SharedPreferences
  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode');

    // Se houver uma preferência salva, use-a.
    // Caso contrário, defina como ThemeMode.light (tema claro) por padrão.
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light; // <--- MUDANÇA AQUI: Padrão para CLARO se não houver preferência salva
    }
    notifyListeners(); // Notifica os ouvintes que o tema foi carregado
  }

  // Define o tema e salva a preferência
  void setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Evita atualizações desnecessárias

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
    notifyListeners(); // Notifica os ouvintes sobre a mudança
  }
}