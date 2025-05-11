import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  comfy,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isDarkMode = false;

  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    _updateTheme();
    notifyListeners();
  }

  void setSystemTheme(bool isDark) {
    _isDarkMode = isDark;
    if (_themeMode == AppThemeMode.system) {
      notifyListeners();
    }
  }

  ThemeData get currentTheme {
    switch (_themeMode) {
      case AppThemeMode.system:
        return _isDarkMode ? AppTheme.getDarkTheme() : AppTheme.getLightTheme();
      case AppThemeMode.light:
        return AppTheme.getLightTheme();
      case AppThemeMode.dark:
        return AppTheme.getDarkTheme();
      case AppThemeMode.comfy:
        return AppTheme.getComfyTheme();
    }
  }

  void _updateTheme() {
    switch (_themeMode) {
      case AppThemeMode.system:
        _isDarkMode =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
        break;
      case AppThemeMode.light:
        _isDarkMode = false;
        break;
      case AppThemeMode.dark:
        _isDarkMode = true;
        break;
      case AppThemeMode.comfy:
        _isDarkMode = false;
        break;
    }
  }
}
