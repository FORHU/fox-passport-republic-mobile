import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';

/// Serves canned responses so the template runs with **no backend**.
///
/// Added to Dio only when `AppConfig.instance.useMock` is true. Because it
/// lives in the Dio pipeline, the real `ApiService` code path is still fully
/// exercised — set `USE_MOCK=false` once your backend is ready and nothing
/// else has to change.
class MockInterceptor extends Interceptor {
  static const Duration _latency = Duration(milliseconds: 600);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await Future<void>.delayed(_latency);
    final path = options.path;
    final body = _asMap(options.data);

    switch (path) {
      case ApiEndpoints.login:
        final email = (body['email'] as String? ?? '').trim();
        final password = body['password'] as String? ?? '';
        if (password.length < 6) {
          handler.reject(
            _error(options, 401, 'Invalid email or password'),
          );
          return;
        }
        handler.resolve(
          _ok(options, {
            'id': '1',
            'email': email,
            'name': email.split('@').first,
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
          }),
        );
      case ApiEndpoints.refresh:
        handler.resolve(
          _ok(options, {
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
          }),
        );
      case ApiEndpoints.logout:
        handler.resolve(_ok(options, {'success': true}));
      case ApiEndpoints.me:
        // Shape must satisfy both AuthRemoteDataSource.checkAuth (needs
        // id/email/name/token) and ProfileRemoteDataSource (needs the extra
        // bio/joinedAt fields) — each feature parses its own DTO from it.
        handler.resolve(
          _ok(options, {
            'id': '1',
            'email': 'ada@example.com',
            'name': 'Ada Lovelace',
            'token': 'mock-access-token',
            'refreshToken': 'mock-refresh-token',
            'bio': 'Building great things with Flutter.',
            'joinedAt': '2024-01-15T00:00:00.000Z',
          }),
        );
      case ApiEndpoints.users:
        handler.resolve(
          _ok(options, {
            'data': [
              {'id': '1', 'name': 'Ada Lovelace'},
              {'id': '2', 'name': 'Alan Turing'},
              {'id': '3', 'name': 'Grace Hopper'},
            ],
          }),
        );
      case ApiEndpoints.nearbyStores:
        handler.resolve(
          _ok(options, {
            'data': [
              {
                'id': '1',
                'name': 'Downtown Market',
                'address': '123 Main St',
                'distanceKm': 0.8,
                'rating': 4.5,
              },
              {
                'id': '2',
                'name': 'Riverside Grocers',
                'address': '45 River Rd',
                'distanceKm': 1.6,
                'rating': 4.2,
              },
              {
                'id': '3',
                'name': 'Uptown Pantry',
                'address': '9 Hilltop Ave',
                'distanceKm': 2.3,
                'rating': 4.8,
              },
            ],
          }),
        );
      default:
        handler.reject(_error(options, 404, 'Unknown endpoint: $path'));
    }
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  Response<dynamic> _ok(RequestOptions options, Map<String, dynamic> data) =>
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: data,
      );

  DioException _error(RequestOptions options, int status, String message) =>
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: {'message': message},
        ),
      );
}
