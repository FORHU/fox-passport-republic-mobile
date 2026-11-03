import 'package:dio/dio.dart';
import 'package:flutter_template/core/services/interceptors/redacting_log_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactSecrets', () {
    test('hides passwords and tokens, however they are spelled', () {
      final out = redactSecrets({
        'email': 'ada@example.com',
        'password': 'hunter2',
        'newPassword': 'x',
        'confirm_password': 'x',
        'Authorization': 'Bearer abc',
        'set-auth-token': 'abc',
        'refreshToken': 'abc',
      })! as Map;

      expect(out['email'], 'ada@example.com');
      for (final key in out.keys.where((k) => k != 'email')) {
        expect(out[key], '***', reason: '$key leaked');
      }
    });

    test('finds secrets nested inside lists and maps', () {
      final out = redactSecrets({
        'data': [
          {
            'user': {'name': 'Ada', 'token': 'abc'},
          },
        ],
      });

      expect('$out', isNot(contains('abc')));
      expect('$out', contains('Ada'));
    });

    test('does not print what is inside an upload', () {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes([1, 2]),
      });

      expect(redactSecrets(form), contains('1 files'));
    });

    test('leaves ordinary values alone', () {
      expect(redactSecrets(null), isNull);
      expect(redactSecrets(3), 3);
      expect(redactSecrets('hello'), 'hello');
    });
  });

  group('RedactingLogInterceptor', () {
    late List<String> lines;
    late Dio dio;

    setUp(() {
      lines = [];
      dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..interceptors.add(RedactingLogInterceptor(lines.add, maxBody: 80))
        ..httpClientAdapter = _Fake();
    });

    test('logs the method, address and status without the password', () async {
      await dio.post<dynamic>(
        '/auth/sign-in/email',
        data: {'email': 'ada@example.com', 'password': 'hunter2'},
        options: Options(headers: {'Authorization': 'Bearer secret-token'}),
      );

      final all = lines.join('\n');
      expect(all, contains('POST http://test.local/auth/sign-in/email'));
      expect(all, contains('ada@example.com'));
      expect(all, contains('200'));
      expect(all, isNot(contains('hunter2')));
      expect(all, isNot(contains('secret-token')));
      // The response held a token too.
      expect(all, isNot(contains('response-token')));
    });

    test('cuts long bodies short', () async {
      await dio.post<dynamic>('/x', data: {'note': 'a' * 500});

      expect(lines.first.length, lessThan(160));
      expect(lines.first, endsWith('…'));
    });

    test('logs a failure and still lets it through', () async {
      await expectLater(
        dio.get<dynamic>('/boom'),
        throwsA(isA<DioException>()),
      );

      expect(lines.join('\n'), contains('ERROR 500'));
    });
  });
}

class _Fake implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/boom') {
      return ResponseBody.fromString(
        '{"message":"no"}',
        500,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromString(
      '{"token":"response-token","ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
