import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/interceptors/auth_interceptor.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

/// Every request is refused with 401, as an expired access token would be.
class _AlwaysUnauthorized implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        '{"message":"Unauthorized"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

typedef _RefreshAnswer = void Function(
  RequestOptions options,
  RequestInterceptorHandler handler,
);

void main() {
  late _MockStorage storage;
  late int refreshCalls;
  late int signedOut;
  late String currentToken;

  setUp(() {
    storage = _MockStorage();
    refreshCalls = 0;
    signedOut = 0;
    currentToken = 'old-access';
    when(storage.readToken).thenAnswer((_) async => currentToken);
    when(storage.readRefreshToken).thenAnswer((_) async => 'refresh-1');
    when(() => storage.saveToken(any())).thenAnswer((invocation) async {
      currentToken = invocation.positionalArguments.first as String;
    });
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(storage.clearSession).thenAnswer((_) async {});
  });

  Dio build(_RefreshAnswer onRefresh) {
    final transport = Dio(
      BaseOptions(baseUrl: 'https://api.example.test/api/v1'),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == ApiEndpoints.refresh) {
              refreshCalls++;
              onRefresh(options, handler);
              return;
            }
            // The replayed request: fine with the new token only.
            if (options.headers['Authorization'] == 'Bearer new-access') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'ok': true},
                ),
              );
              return;
            }
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 401,
                ),
              ),
            );
          },
        ),
      );

    return Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = _AlwaysUnauthorized()
      ..interceptors.add(
        AuthInterceptor(
          storage,
          baseUrl: 'https://api.example.test/api/v1',
          refreshClient: transport,
          onUnauthenticated: () => signedOut++,
        ),
      );
  }

  void refreshSucceeds(RequestOptions o, RequestInterceptorHandler h) =>
      h.resolve(
        Response<dynamic>(
          requestOptions: o,
          statusCode: 200,
          data: {'accessToken': 'new-access', 'refreshToken': 'refresh-2'},
        ),
      );


  _RefreshAnswer refreshFailsWith(int? status, {DioExceptionType? type}) {
    return (o, h) => h.reject(
          DioException(
            requestOptions: o,
            type: type ?? DioExceptionType.badResponse,
            response: status == null
                ? null
                : Response<dynamic>(requestOptions: o, statusCode: status),
          ),
        );
  }

  test('a dropped connection while refreshing does not sign the user out',
      () async {
    final client = build(
      refreshFailsWith(null, type: DioExceptionType.connectionError),
    );

    await expectLater(
      client.get<dynamic>('/bookings/upcoming'),
      throwsA(isA<DioException>()),
    );

    expect(signedOut, 0);
    verifyNever(storage.clearSession);
  });

  test('a server error while refreshing keeps the session too', () async {
    final client = build(refreshFailsWith(503));

    await expectLater(
      client.get<dynamic>('/bookings/upcoming'),
      throwsA(isA<DioException>()),
    );

    expect(signedOut, 0);
    verifyNever(storage.clearSession);
  });

  test('a refresh token the server refuses ends the session', () async {
    final client = build(refreshFailsWith(401));

    await expectLater(
      client.get<dynamic>('/bookings/upcoming'),
      throwsA(isA<DioException>()),
    );

    expect(signedOut, 1);
    verify(storage.clearSession).called(1);
  });

  test('a burst of 401s refreshes once, then retries with the new token',
      () async {
    final client = build(refreshSucceeds);

    final results = await Future.wait([
      client.get<dynamic>('/bookings/upcoming'),
      client.get<dynamic>('/passport/me'),
      client.get<dynamic>('/conversations'),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200, 200]);
    expect(refreshCalls, 1, reason: 'the others reuse the new token');
    expect(signedOut, 0);
  });
}
