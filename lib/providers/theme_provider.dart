import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _settingsBox = 'settings';
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  
  // Theme getter for display text
  String get themeName {
    switch (_themeMode) {
      case ThemeMode.system: return 'Системная';
      case ThemeMode.light: return 'Светлая';
      case ThemeMode.dark: return 'Темная';
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_settingsBox);
    final savedIndex = box.get(_themeKey) as int?;
    
    if (savedIndex != null) {
      _themeMode = ThemeMode.values[savedIndex];
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final box = await Hive.openBox(_settingsBox);
    await box.put(_themeKey, mode.index);
  }
}
