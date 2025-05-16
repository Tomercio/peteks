import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/privacy_policy_screen.dart';
import 'ui/screens/terms_screen.dart';
import 'ui/screens/about_screen.dart';
import 'services/storage_service.dart';
import 'services/image_service.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'services/google_drive_service.dart';

// Add enum for theme modes
enum AppThemeMode { system, comfyLight, comfyDark }

// comfyLight Theme
final ThemeData comfyLightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Nunito',
  scaffoldBackgroundColor: const Color(0xFFFFF7ED), // Soft Linen
  cardColor: const Color(0xFFFEF9F4), // Cream Paper
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFFF49390), // Cozy Coral
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFFBFC9A9), // Sage Green
    onSecondary: const Color(0xFF4B3D30),
    error: Colors.red,
    onError: Colors.white,
    surface: const Color(0xFFFEF9F4), // Cream Paper
    onSurface: const Color(0xFF4B3D30),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFF4B3D30),
      fontFamily: 'Nunito',
    ), // Espresso Brown
    bodyMedium: TextStyle(
      color: Color(0xFF7C6F62),
      fontFamily: 'Nunito',
    ), // Clay Brown
    titleLarge: TextStyle(color: Color(0xFF4B3D30), fontFamily: 'Nunito'),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEB9780), // Coral Pink
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontFamily: 'Nunito'),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFF1E4D7)), // Pale Almond
    ),
    filled: true,
    fillColor: Color(0xFFFEF9F4), // Card BG
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

// comfyDark Theme
final ThemeData comfyDarkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'Nunito',
  scaffoldBackgroundColor: const Color(0xFF2E241E), // Deep Cocoa
  cardColor: const Color(0xFF3B2F26), // Dark Mocha
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFEC8D80), // Coral Glow
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFF857C5A), // Olive Brown
    onSecondary: const Color(0xFFF4ECD9),
    error: Colors.red,
    onError: Colors.white,
    surface: const Color(0xFF3B2F26), // Dark Mocha
    onSurface: const Color(0xFFF4ECD9),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color(0xFFF4ECD9),
      fontFamily: 'Nunito',
    ), // Vanilla Cream
    bodyMedium: TextStyle(
      color: Color(0xFFC7BBA7),
      fontFamily: 'Nunito',
    ), // Light Sand
    titleLarge: TextStyle(color: Color(0xFFF4ECD9), fontFamily: 'Nunito'),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFEB9780), // Coral Pink
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontFamily: 'Nunito'),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF4A3B2F)), // Cocoa Tint
    ),
    filled: true,
    fillColor: Color(0xFF3B2F26), // Card BG
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.init();

  // Initialize critical services before runApp
  await ImageService.init();

  // Persistent Google sign-in if user previously signed in
  final googleSignedIn =
      storageService.getSetting('google_signed_in', defaultValue: false);
  if (googleSignedIn == true) {
    await GoogleDriveService().signInSilently();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(storageService: storageService),
    ),
  );
}

class MyApp extends StatefulWidget {
  final StorageService storageService;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key, required this.storageService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final savedThemeMode = widget.storageService.getSetting(
      'themeMode',
      defaultValue: 'system',
    );
    setState(() {
      switch (savedThemeMode) {
        case 'comfyLight':
          _themeMode = AppThemeMode.comfyLight;
          break;
        case 'comfyDark':
          _themeMode = AppThemeMode.comfyDark;
          break;
        default:
          _themeMode = AppThemeMode.system;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(
            value: widget.storageService),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(_themeMode, widget.storageService),
        ),
        Provider<ImageService>(create: (_) => ImageService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          final themeMode = themeService.themeMode;
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Peteks',
                debugShowCheckedModeBanner: false,
                navigatorKey: MyApp.navigatorKey,
                themeMode: switch (themeMode) {
                  AppThemeMode.system => ThemeMode.system,
                  AppThemeMode.comfyLight => ThemeMode.light,
                  AppThemeMode.comfyDark => ThemeMode.dark,
                },
                theme: comfyLightTheme,
                darkTheme: comfyDarkTheme,
                home: const SplashScreen(),
                routes: {
                  '/settings': (context) => const SettingsScreen(),
                  '/privacy': (context) => const PrivacyPolicyScreen(),
                  '/terms': (context) => const TermsScreen(),
                  '/about': (context) => const AboutScreen(),
                },
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  // Add more locales if needed
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// Theme service to manage app theme
class ThemeService extends ChangeNotifier {
  AppThemeMode _themeMode;
  final StorageService storageService;

  ThemeService(this._themeMode, this.storageService);

  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == AppThemeMode.comfyDark;
  bool get isLightMode => _themeMode == AppThemeMode.comfyLight;
  bool get isSystemMode => _themeMode == AppThemeMode.system;

  void setThemeMode(AppThemeMode mode) {
    _themeMode = mode;
    String themeModeString;
    switch (mode) {
      case AppThemeMode.comfyLight:
        themeModeString = 'comfyLight';
        break;
      case AppThemeMode.comfyDark:
        themeModeString = 'comfyDark';
        break;
      default:
        themeModeString = 'system';
        break;
    }
    storageService.saveSetting('themeMode', themeModeString);
    notifyListeners();
  }

  void toggleTheme() {
    switch (_themeMode) {
      case AppThemeMode.system:
        setThemeMode(AppThemeMode.comfyLight);
        break;
      case AppThemeMode.comfyLight:
        setThemeMode(AppThemeMode.comfyDark);
        break;
      case AppThemeMode.comfyDark:
        setThemeMode(AppThemeMode.system);
        break;
    }
  }

  void setLight() => setThemeMode(AppThemeMode.comfyLight);
  void setDark() => setThemeMode(AppThemeMode.comfyDark);
  void setSystem() => setThemeMode(AppThemeMode.system);
}
