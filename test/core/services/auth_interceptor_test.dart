import 'package:dio/dio.dart';
import 'package:flutter_template/core/services/interceptors/auth_interceptor.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageService extends Mock implements StorageService {}

class _UnauthorizedAdapter implements HttpClientAdapter {
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

void main() {
  test('refreshes with the API token contract and replays the request',
      () async {
    final storage = _MockStorageService();
    when(storage.readToken).thenAnswer((_) async => 'old-access');
    when(storage.readRefreshToken).thenAnswer((_) async => 'old-refresh');
    when(() => storage.saveToken('new-access')).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken('new-refresh'))
        .thenAnswer((_) async {});

    final transport = Dio(
      BaseOptions(baseUrl: 'https://api.example.test/api/v1'),
    );
    transport.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/refresh-token') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'accessToken': 'new-access',
                  'refreshToken': 'new-refresh',
                },
              ),
            );
            return;
          }

          if (options.headers['Authorization'] == 'Bearer new-access') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true},
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
                data: {'message': 'Unauthorized'},
              ),
            ),
          );
        },
      ),
    );

    final client = Dio(
      BaseOptions(baseUrl: 'https://api.example.test/api/v1'),
    )
      ..httpClientAdapter = _UnauthorizedAdapter()
      ..interceptors.add(
        AuthInterceptor(
          storage,
          baseUrl: 'https://api.example.test/api/v1',
          refreshClient: transport,
        ),
      );

    final response = await client.get<dynamic>('/bookings/upcoming');

    expect(response.data, {'success': true});
    verify(() => storage.saveToken('new-access')).called(1);
    verify(() => storage.saveRefreshToken('new-refresh')).called(1);
  });
}
