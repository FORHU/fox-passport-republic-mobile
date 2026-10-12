import 'package:flutter_template/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a path of the FoxPassport web app in the system browser, for flows
/// the mobile app doesn't have yet (role applications, creator dashboard).
///
/// Returns false when `WEB_APP_URL` isn't configured or the OS can't open it,
/// so the caller can tell the user instead of failing silently.
Future<bool> openWebApp(String path) async {
  final base = AppConfig.instance.webAppUrl;
  if (base.isEmpty) return false;

  final trimmed =
      base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final uri = Uri.tryParse('$trimmed$path');
  if (uri == null) return false;

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
