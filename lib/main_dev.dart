import 'package:flutter_template/bootstrap.dart';
import 'package:flutter_template/core/config/app_config.dart';

/// Development entry point: `flutter run -t lib/main_dev.dart`.
/// Loads the dev environment file, including the API host and mock opt-in.
Future<void> main() => bootstrap(
      const AppConfig.dev(),
      dotEnvFile: '.env.dev',
    );
