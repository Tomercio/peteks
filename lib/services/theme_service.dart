import 'package:flutter/material.dart';

class ThemeService {
  final ThemeMode themeMode;
  final Function(ThemeMode) setThemeMode;

  const ThemeService(this.themeMode, this.setThemeMode);

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;

  void toggleTheme() {
    if (themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  void setLight() => setThemeMode(ThemeMode.light);
  void setDark() => setThemeMode(ThemeMode.dark);
  void setSystem() => setThemeMode(ThemeMode.system);
}
