import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/interceptors/auth_interceptor.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

/// Answers every request with [status], or drops the connection when null.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);

  final int? status;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    if (status == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{}',
      status!,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MockStorage storage;
  late int signedOut;
  late String? currentToken;

  setUp(() {
    storage = _MockStorage();
    signedOut = 0;
    currentToken = 'session-token';
    when(storage.readToken).thenAnswer((_) async => currentToken);
    when(storage.clearSession).thenAnswer((_) async {
      currentToken = null;
    });
  });

  Dio build(_Adapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
        ..httpClientAdapter = adapter
        ..interceptors.add(
          AuthInterceptor(storage, onUnauthenticated: () => signedOut++),
        );

  test('sends the session token as a bearer token', () async {
    final adapter = _Adapter(200);
    await build(adapter).get<dynamic>('/profile');

    expect(
      adapter.seen.single.headers['Authorization'],
      'Bearer session-token',
    );
  });

  test('does not send a token to sign-in', () async {
    final adapter = _Adapter(200);
    await build(adapter).post<dynamic>(ApiEndpoints.login);

    expect(adapter.seen.single.headers['Authorization'], isNull);
  });

  test('a 401 on a signed-in request ends the session', () async {
    await expectLater(
      build(_Adapter(401)).get<dynamic>('/bookings/upcoming'),
      throwsA(isA<DioException>()),
    );

    expect(signedOut, 1);
    verify(storage.clearSession).called(1);
  });

  test('a dropped connection does not sign the user out', () async {
    await expectLater(
      build(_Adapter(null)).get<dynamic>('/bookings/upcoming'),
      throwsA(isA<DioException>()),
    );

    expect(signedOut, 0);
    verifyNever(storage.clearSession);
  });

  test('a server error does not sign the user out', () async {
    await expectLater(
      build(_Adapter(503)).get<dynamic>('/bookings/upcoming'),
      throwsA(isA<DioException>()),
    );

    expect(signedOut, 0);
    verifyNever(storage.clearSession);
  });

  test('a burst of 401s signs the user out once', () async {
    final client = build(_Adapter(401));

    await Future.wait(
      ['/bookings/upcoming', '/passport/me', '/conversations'].map(
        (p) => client.get<dynamic>(p).catchError(
              (_) => Response<dynamic>(requestOptions: RequestOptions(path: p)),
            ),
      ),
    );

    expect(signedOut, 1);
    verify(storage.clearSession).called(1);
  });
}
