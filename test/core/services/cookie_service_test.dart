import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/cookie_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

/// Answers every request with 200 and a Better Auth session cookie, and keeps
/// each request so a test can read the headers that were sent.
class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'set-cookie': ['better-auth.session_token=abc; Path=/; HttpOnly'],
      },
    );
  }
}

void main() {
  setUpAll(() {
    AppConfig.instance = const AppConfig.prod();
  });

  group('CookieService', () {
    test('initializes with default CookieJar', () {
      final service = CookieService();
      expect(service.jar, isA<CookieJar>());
    });

    test('accepts custom CookieJar and clears cookies', () async {
      final customJar = CookieJar();
      final service = CookieService(jar: customJar);

      await service.jar.saveFromResponse(
        Uri.parse('http://localhost:6002'),
        [Cookie('accessToken', 'test-token')],
      );

      var cookies =
          await service.jar.loadForRequest(Uri.parse('http://localhost:6002'));
      expect(cookies.length, 1);
      expect(cookies.first.name, 'accessToken');

      await service.clearCookies();
      cookies = await service.jar.loadForRequest(
        Uri.parse('http://localhost:6002'),
      );
      expect(cookies.isEmpty, true);
    });

    // mobile#284: Better Auth refuses a POST that carries a cookie but no
    // `Origin` ("Missing or null Origin"), and native requests have no
    // Origin. A cookie the server sets (sign-up signs the person in) must
    // never be sent back; the bearer token is what authenticates.
    test('native requests never send back a cookie the server set', () async {
      final storage = MockStorageService();
      when(storage.readToken).thenAnswer((_) async => 'session-token');

      final adapter = _RecordingAdapter();
      final api = ApiService(
        storage: storage,
        cookieService: CookieService(),
        dio: Dio(BaseOptions(baseUrl: 'http://localhost:6002/api/v1'))
          ..httpClientAdapter = adapter,
      );

      await api.post('/auth/sign-up/email', {'email': 'a@b.co'});
      await api.post('/auth/email-otp/verify-email', {
        'email': 'a@b.co',
        'otp': '123456',
      });

      final verify = adapter.requests.last;
      expect(verify.headers['cookie'], isNull);
      expect(verify.headers['Authorization'], 'Bearer session-token');
      expect(api.client.interceptors.any((i) => i is CookieManager), isFalse);
    });
  });
}
