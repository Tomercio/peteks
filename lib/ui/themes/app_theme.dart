import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors (original purple palette)
  static const Color _lightPrimaryColor = Color(0xFFB39DDB); // Light purple
  static const Color _lightAccentColor = Color(0xFF9575CD); // Accent purple
  static const Color _lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightErrorColor = Color(0xFFB00020);

  static const Color _lightAppBarBg = Color(0xFFB39DDB); // Light purple
  static const Color _lightAppBarFg = Colors.white;
  static const Color _lightFabColor = Color(0xFFB39DDB); // Light purple
  static const Color _lightTitleText = Color(0xFF512DA8); // Deep purple
  static const Color _lightBodyText =
      Color(0xFF5E35B1); // Slightly lighter deep purple

  // Dark theme colors (original purple palette)
  static const Color _darkPrimaryColor = Color(0xFF7C4DFF); // Deep purple
  static const Color _darkAccentColor = Color(0xFF9575CD); // Accent purple
  static const Color _darkBackgroundColor =
      Color(0xFF121212); // Restored to dark
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E); // Restored to dark
  static const Color _darkErrorColor = Color(0xFFCF6679);
  static const Color _darkTextColor = Colors.white;
  static const Color _darkAppBarBg =
      Color(0xFF232228); // Dark gray for app bar in dark mode
  static const Color _darkAppBarFg = Colors.white;

  // Note colors palette (original purples and some accents)
  static const List<Color> notePalette = [
    Colors.white,
    Colors.black,
    Color(0xFF424242), // Dark gray
    Color(0xFF425058), // Blue-gray
    Color(0xFF98FF98), // Mint
    Color(0xFF3EB489), // Dark Mint
    Color(0xFFFCE4EC), // Pink
    Color(0xFFE57373), // Red
    Color(0xFFFFF8E1), // Yellow
    Color(0xFFE1F5FE), // Soft blue
    Color(0xFFB39DDB), // Brand purple (optional)
    Color(0xFF232228), // Brand dark (optional)
  ];

  static const List<Color> darkNotePalette = [
    Colors.black,
    Color(0xFF424242), // Dark gray
    Color(0xFF425058), // Blue-gray
    Color(0xFF3EB489), // Dark Mint
    Color(0xFF98FF98), // Mint
    Color(0xFFFCE4EC), // Pink
    Color(0xFFE57373), // Red
    Color(0xFFFFF8E1), // Yellow
    Color(0xFFE1F5FE), // Soft blue
    Color(0xFFB39DDB), // Brand purple (optional)
    Color(0xFF232228), // Brand dark (optional)
  ];

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _lightPrimaryColor,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimaryColor,
      secondary: _lightAccentColor,
      surface: _lightSurfaceColor,
      error: _lightErrorColor,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightAppBarBg,
      foregroundColor: _lightAppBarFg,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightFabColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _lightTitleText,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _lightTitleText,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _lightTitleText,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _lightTitleText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _lightTitleText,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _lightBodyText),
      bodyMedium: TextStyle(fontSize: 14, color: _lightBodyText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimaryColor,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimaryColor,
      secondary: _darkAccentColor,
      surface: _darkSurfaceColor,
      error: _darkErrorColor,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkAppBarBg,
      foregroundColor: _darkAppBarFg,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _darkSurfaceColor, // Light gray for cards
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _darkPrimaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkTextColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _darkTextColor),
      bodyMedium: TextStyle(fontSize: 14, color: _darkTextColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C), // Restored to dark
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: const BorderSide(color: _darkPrimaryColor),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(_darkPrimaryColor),
      trackColor: WidgetStateProperty.all(_darkPrimaryColor),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Color(0xFF232228),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      color: _darkPrimaryColor,
      selectedColor: Colors.white,
      fillColor: _darkPrimaryColor,
      borderColor: _darkPrimaryColor,
      selectedBorderColor: _darkPrimaryColor,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _darkPrimaryColor,
      textColor: Colors.white,
      selectedColor: _darkPrimaryColor,
    ),
  );

  // Get current theme colors based on brightness
  static List<Color> getNoteColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkNotePalette : notePalette;
  }
}
