import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStore {
  ThemeStore._();

  static final ThemeStore instance = ThemeStore._();

  static const _themeModeKey = 'theme_mode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    mode.value = _themeModeFromString(stored) ?? ThemeMode.dark;
    _loaded = true;
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(newMode));
    mode.value = newMode;
  }

  Future<void> toggleTheme() async {
    final nextMode = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  bool get isDarkMode => mode.value == ThemeMode.dark;

  ThemeMode? _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  String _themeModeToString(ThemeMode value) {
    switch (value) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
