import 'package:flutter_template/core/config/app_config.dart';

/// The address to load an image from.
///
/// Normally [url] as stored. In development, an address on `localhost` or
/// `127.0.0.1` is pointed at [AppConfig.assetHostOverride] when one is set,
/// because on an Android emulator `localhost` is the emulator, not your
/// computer. Public addresses are never touched.
String resolveAssetUrl(String url) {
  final String host;
  try {
    host = AppConfig.instance.assetHostOverride;
  } on Object {
    // Config not loaded (some tests, very early start): leave the URL alone.
    return url;
  }
  if (host.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  const loopback = {'localhost', '127.0.0.1'};
  if (!loopback.contains(uri.host)) return url;
  return uri.replace(host: host).toString();
}
