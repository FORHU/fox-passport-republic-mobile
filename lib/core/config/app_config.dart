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
    this.useMock = false,
    this.googleServerClientId = '',
    this.googleClientId = '',
    this.facebookNativeEnabled = false,
    this.socialRedirectOrigin = 'foxpassport://app',
    this.webAppUrl = '',
    this.mapboxToken = '',
    this.assetHostOverride = '',
  });

  /// Builds config from `flutter_dotenv` values loaded at runtime.
  /// Used by the default entry point (`main.dart`).
  factory AppConfig.fromEnvironment() {
    final envString = dotenv.env['ENVIRONMENT'] ?? 'dev';
    return AppConfig(
      environment: envString == 'prod' ? Environment.prod : Environment.dev,
      appName: dotenv.env['APP_NAME'] ?? 'Fox Passport',
      baseUrl: dotenv.env['BASE_URL'] ?? 'http://localhost:6002/api/v1',
      enableLogging: (dotenv.env['ENABLE_LOGGING'] ??
                  (envString != 'prod' ? 'true' : 'false'))
              .toLowerCase() ==
          'true',
      useMock: (dotenv.env['USE_MOCK'] ?? 'false').toLowerCase() == 'true',
      googleServerClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '',
      googleClientId: dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
      facebookNativeEnabled:
          (dotenv.env['FACEBOOK_NATIVE'] ?? 'false').toLowerCase() == 'true',
      socialRedirectOrigin:
          dotenv.env['SOCIAL_REDIRECT_ORIGIN'] ?? 'foxpassport://app',
      webAppUrl: (dotenv.env['WEB_APP_URL'] ?? '').trim(),
      mapboxToken: (dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '').trim(),
      assetHostOverride: (dotenv.env['ASSET_HOST_OVERRIDE'] ?? '').trim(),
    );
  }

  /// Explicit development config used by `main_dev.dart` — points at local
  /// Fox Passport Republic API on port 6002.
  const AppConfig.dev({this.useMock = false})
      : environment = Environment.dev,
        appName = 'Fox Passport (Dev)',
        baseUrl = 'http://localhost:6002/api/v1',
        enableLogging = true,
        googleServerClientId = '',
        googleClientId = '',
        facebookNativeEnabled = false,
        socialRedirectOrigin = 'foxpassport://app',
        webAppUrl = '',
        mapboxToken = '',
        assetHostOverride = '';

  /// Explicit production config used by `main_prod.dart` — logging off.
  const AppConfig.prod()
      : environment = Environment.prod,
        appName = 'Fox Passport',
        baseUrl = 'http://localhost:6002/api/v1',
        enableLogging = false,
        useMock = false,
        googleServerClientId = '',
        googleClientId = '',
        facebookNativeEnabled = false,
        socialRedirectOrigin = 'foxpassport://app',
        webAppUrl = '',
        mapboxToken = '',
        assetHostOverride = '';

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  /// Whether API requests should be served by the mock interceptor.
  final bool useMock;

  /// Dev only. Photos uploaded to a local MinIO are stored with a
  /// `localhost` address, which on an Android emulator is the emulator
  /// itself. Set this to `10.0.2.2` (the emulator's name for your computer)
  /// and such addresses are read through it. Empty leaves URLs alone.
  final String assetHostOverride;

  /// Google OAuth *web* client ID. Passed to the native SDK as the server
  /// client ID so the ID token it returns is addressed to this backend (the
  /// API verifies `aud` against its own GOOGLE_CLIENT_ID). Empty disables
  /// native Google sign-in and falls back to the browser flow.
  final String googleServerClientId;

  /// iOS OAuth client ID (needed on iOS only; Android resolves it from the
  /// package name and signing certificate registered in Google Cloud).
  final String googleClientId;

  /// Whether the Facebook SDK is configured natively (app ID and client token
  /// in AndroidManifest / Info.plist). Off falls back to the browser flow.
  final bool facebookNativeEnabled;

  /// Where the API sends the system browser back to after the browser flow.
  /// Must be listed in the API's MOBILE_REDIRECT_ORIGINS and use the scheme
  /// registered in AndroidManifest.xml.
  final String socialRedirectOrigin;

  /// Base URL of the FoxPassport web app, for flows the mobile app doesn't
  /// have yet (role applications, creator dashboard). Empty disables them.
  final String webAppUrl;

  /// Mapbox *public* access token (`pk.…`) for the globe. Public by design —
  /// it ships in the app like the web app's `NEXT_PUBLIC_MAPBOX_TOKEN`;
  /// restrict it by URL / bundle in the Mapbox account. Never put a secret
<<<<<<< HEAD
  /// `sk.…` token here. Empty shows a static placeholder instead of the
  /// globe.
=======
  /// `sk.…` token here. Empty shows a static placeholder instead of the globe.
>>>>>>> 8685e43a59ba05d13b4e6e8d7f8aae2d44061c70
  final String mapboxToken;

  /// The scheme part of [socialRedirectOrigin], e.g. `foxpassport`.
  String get socialRedirectScheme => Uri.parse(socialRedirectOrigin).scheme;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;

  /// Set once by `bootstrap()` before `runApp`. Reading it before then throws.
  static late AppConfig instance;
}
