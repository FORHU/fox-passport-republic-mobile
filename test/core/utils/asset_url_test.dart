import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/config/environment.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig _config(String override) => AppConfig(
      environment: Environment.dev,
      appName: 'test',
      baseUrl: 'http://localhost:6002/api/v1',
      assetHostOverride: override,
    );

void main() {
  const minio = 'http://localhost:9000/fox-passport-dev/users/u/a.jpg';

  test('leaves addresses alone when no override is set', () {
    AppConfig.instance = _config('');
    expect(resolveAssetUrl(minio), minio);
  });

  test('points a localhost photo at the emulator host, keeping the rest', () {
    AppConfig.instance = _config('10.0.2.2');
    expect(
      resolveAssetUrl(minio),
      'http://10.0.2.2:9000/fox-passport-dev/users/u/a.jpg',
    );
    expect(
      resolveAssetUrl('http://127.0.0.1:9000/b/c.png?x=1'),
      'http://10.0.2.2:9000/b/c.png?x=1',
    );
  });

  test('never touches a public address', () {
    AppConfig.instance = _config('10.0.2.2');
    const cdn = 'https://d2uywbslpln2xw.cloudfront.net/users/u/a.jpg';
    expect(resolveAssetUrl(cdn), cdn);
  });
}
