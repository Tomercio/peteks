import 'package:flutter/material.dart';

class AppTheme {
  // Comfy Theme Colors
  static const comfyColors = {
    'background': Color(0xFFFFF7ED), // Soft Linen
    'card': Color(0xFFFEF9F4), // Cream Paper
    'primary': Color(0xFFF49390), // Warm Coral
    'secondary': Color(0xFFBFC9A9), // Sage Green
    'accent': Color(0xFFF4C27C), // Cozy Amber
    'textDark': Color(0xFF4B3D30), // Soft Espresso
    'textLight': Color(0xFF7C6F62), // Gentle Clay
    'buttonBg': Color(0xFFEB9780), // Muted Terracotta
    'heartIcon': Color(0xFFEC8D80), // Coral Pink Outline
  };

  // Dark Theme Colors
  static const darkColors = {
    'background': Color(0xFF2E241E), // Deep Cocoa
    'card': Color(0xFF3B2F26), // Dark Mocha
    'primaryText': Color(0xFFF4ECD9), // Vanilla Cream
    'secondaryText': Color(0xFFC7BBA7), // Light Sand
    'accent': Color(0xFFEC8D80), // Coral Glow
    'tagBg': Color(0xFF857C5A), // Olive Brown
    'buttonBg': Color(0xFFEB9780), // Coral Pink
    'buttonText': Color(0xFFFFFFFF), // White
    'border': Color(0xFF4A3B2F), // Cocoa Tint
  };

  // Light Theme Colors
  static const lightColors = {
    'background': Color(0xFFFFF7ED), // Soft Linen
    'card': Color(0xFFFEF9F4), // Cream Paper
    'primaryText': Color(0xFF4B3D30), // Espresso Brown
    'secondaryText': Color(0xFF7C6F62), // Clay Brown
    'accent': Color(0xFFF49390), // Cozy Coral
    'tagBg': Color(0xFFBFC9A9), // Sage Green
    'buttonBg': Color(0xFFEB9780), // Coral Pink
    'buttonText': Color(0xFFFFFFFF), // White
    'border': Color(0xFFF1E4D7), // Pale Almond
  };

  static ThemeData getComfyTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.light(
        primary: comfyColors['primary']!,
        secondary: comfyColors['secondary']!,
        surface: comfyColors['card']!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: comfyColors['textDark']!,
      ),
      scaffoldBackgroundColor: comfyColors['background'],
      cardColor: comfyColors['card'],
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: comfyColors['textDark']),
        bodyMedium: TextStyle(color: comfyColors['textDark']),
        titleLarge: TextStyle(color: comfyColors['textDark']),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: comfyColors['background'],
        foregroundColor: comfyColors['textDark'],
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: comfyColors['buttonBg'],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.dark(
        primary: darkColors['accent']!,
        secondary: darkColors['tagBg']!,
        surface: darkColors['card']!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkColors['primaryText']!,
      ),
      scaffoldBackgroundColor: darkColors['background'],
      cardColor: darkColors['card'],
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: darkColors['primaryText']),
        bodyMedium: TextStyle(color: darkColors['primaryText']),
        titleLarge: TextStyle(color: darkColors['primaryText']),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors['background'],
        foregroundColor: darkColors['primaryText'],
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColors['buttonBg'],
          foregroundColor: darkColors['buttonText'],
        ),
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.light(
        primary: lightColors['accent']!,
        secondary: lightColors['tagBg']!,
        surface: lightColors['card']!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightColors['primaryText']!,
      ),
      scaffoldBackgroundColor: lightColors['background'],
      cardColor: lightColors['card'],
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: lightColors['primaryText']),
        bodyMedium: TextStyle(color: lightColors['primaryText']),
        titleLarge: TextStyle(color: lightColors['primaryText']),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColors['background'],
        foregroundColor: lightColors['primaryText'],
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColors['buttonBg'],
          foregroundColor: lightColors['buttonText'],
        ),
      ),
    );
  }
}
