import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

/// A Dio adapter that returns a canned HTTP response, so tests exercise the
/// real ApiService pipeline (interceptors + error mapping) with no network.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Object body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

ApiService _apiReturning({required int status, required Object body}) {
  final storage = MockStorageService();
  when(storage.readToken).thenAnswer((_) async => null);
  when(storage.clearSession).thenAnswer((_) async {});

  final dio = Dio()
    ..httpClientAdapter = _StubAdapter(statusCode: status, body: body);
  return ApiService(storage: storage, dio: dio);
}

void main() {
  setUpAll(() {
    // prod config => no mock interceptor, no verbose logging.
    AppConfig.instance = const AppConfig.prod();
  });

  group('ApiService error mapping', () {
    test('returns decoded body on 200', () async {
      final api = _apiReturning(status: 200, body: {'ok': true});
      final data = await api.get('/data');
      expect((data as Map)['ok'], isTrue);
    });

    test('throws UnauthorizedException on 401', () async {
      final api = _apiReturning(status: 401, body: {'message': 'nope'});
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            'nope',
          ),
        ),
      );
    });

    test('throws ServerException on a 4xx (non-auth) response', () async {
      final api = _apiReturning(status: 422, body: {'message': 'boom'});
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            422,
          ),
        ),
      );
    });

    test('a 500 shows a plain sentence, not the server body or Dio text',
        () async {
      final api = _apiReturning(
        status: 500,
        body: {'message': 'ECONNREFUSED at pool.query (db.js:12)'},
      );
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having(
                (e) => e.message,
                'message',
                ApiService.serverErrorMessage,
              ),
        ),
      );
    });

    test('a 500 with no message still shows the plain sentence', () async {
      final api = _apiReturning(status: 500, body: <String, Object>{});
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            ApiService.serverErrorMessage,
          ),
        ),
      );
    });

    test('the message never carries the text Dio writes for developers',
        () async {
      for (final status in [400, 404, 422, 500, 502]) {
        final api = _apiReturning(status: status, body: <String, Object>{});
        await expectLater(
          api.get('/data'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              allOf(
                isNot(contains('validateStatus')),
                isNot(contains('developer.mozilla.org')),
                isNot(contains('RequestOptions')),
              ),
            ),
          ),
        );
      }
    });

    test('a 4xx without a message gets the plain sentence', () async {
      final api = _apiReturning(status: 404, body: <String, Object>{});
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            ApiService.serverErrorMessage,
          ),
        ),
      );
    });

    test('a 4xx keeps the message the server wrote for people', () async {
      final api = _apiReturning(
        status: 409,
        body: {'message': 'User already exists'},
      );
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'User already exists',
          ),
        ),
      );
    });

    test('a blank message is treated as none', () async {
      final api = _apiReturning(status: 422, body: {'message': '   '});
      await expectLater(
        api.get('/data'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            ApiService.serverErrorMessage,
          ),
        ),
      );
    });
  });
}
