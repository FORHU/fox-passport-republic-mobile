import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_template/core/config/environment.dart';

/// Per-environment settings, fixed at startup.
///
/// One [AppConfig] is chosen by the entry point (main_dev/main_prod) and
/// assigned to [instance] inside `bootstrap()`. Read it anywhere via
/// `AppConfig.instance`.
///
/// The default entry point (`main.dart`) builds it via
/// [AppConfig.fromEnvironment], which reads from the `.env.*` asset loaded
/// by `flutter_dotenv`.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    this.enableLogging = false,
  });

  /// Builds config from `flutter_dotenv` values loaded at runtime.
  /// Used by the default entry point (`main.dart`).
  factory AppConfig.fromEnvironment() {
    final envString = dotenv.env['ENVIRONMENT'] ?? 'dev';
    return AppConfig(
      environment: envString == 'prod' ? Environment.prod : Environment.dev,
      appName: dotenv.env['APP_NAME'] ?? 'flutter_template',
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      enableLogging:
          (dotenv.env['ENABLE_LOGGING'] ??
                  (envString != 'prod' ? 'true' : 'false'))
              .toLowerCase() ==
          'true',
    );
  }

  /// Explicit development config used by `main_dev.dart` — points at local
  /// Fox Passport Republic API on port 6002.
  const AppConfig.dev()
    : environment = Environment.dev,
      appName = 'Fox Passport (Dev)',
      baseUrl = 'http://localhost:6002/api/v1',
      enableLogging = true;

  /// Explicit production config used by `main_prod.dart` — logging off.
  const AppConfig.prod()
    : environment = Environment.prod,
      appName = 'Fox Passport',
      baseUrl = 'http://localhost:6002/api/v1',
      enableLogging = false;

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
