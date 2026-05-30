enum AppFlavor { dev, prod }

/// Build-time flavor configuration.
/// Set by passing --dart-define=FLAVOR=dev|prod when building.
class AppConfig {
  static const String _flavorString =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static AppFlavor get flavor =>
      _flavorString == 'dev' ? AppFlavor.dev : AppFlavor.prod;

  static bool get isDev => flavor == AppFlavor.dev;
  static bool get isProd => flavor == AppFlavor.prod;

  static String get appName => isDev ? 'Peteks Dev' : 'Peteks';
}
