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

    if (path == ApiEndpoints.locationCountries) {
      handler.resolve(
        _ok(options, {
          'data': [
            {'code': 'PH', 'name': 'Philippines'},
            {'code': 'US', 'name': 'United States'},
            {'code': 'GB', 'name': 'United Kingdom'},
          ],
        }),
      );
      return;
    }

    final locationPath =
        RegExp(r'^/locations/countries/([A-Z]{2})/(states|cities)$')
            .firstMatch(path);
    if (locationPath != null) {
      final countryCode = locationPath.group(1);
      final resource = locationPath.group(2);
      if (resource == 'states') {
        handler.resolve(
          _ok(options, {
            'data': switch (countryCode) {
              'PH' => [
                  {'code': 'NCR', 'name': 'Metro Manila'},
                  {'code': 'CEB', 'name': 'Central Visayas'},
                ],
              'US' => [
                  {'code': 'CA', 'name': 'California'},
                  {'code': 'NY', 'name': 'New York'},
                ],
              'GB' => [
                  {'code': 'ENG', 'name': 'England'},
                  {'code': 'SCT', 'name': 'Scotland'},
                ],
              _ => <Map<String, String>>[],
            },
          }),
        );
        return;
      }

      final region = options.queryParameters['state'];
      handler.resolve(
        _ok(options, {
          'data': switch ((countryCode, region)) {
            ('PH', 'NCR') => ['Manila', 'Quezon City', 'Makati'],
            ('PH', 'CEB') => ['Cebu City', 'Lapu-Lapu City', 'Mandaue'],
            ('US', 'CA') => ['Los Angeles', 'San Francisco', 'San Diego'],
            ('US', 'NY') => ['New York City', 'Buffalo', 'Rochester'],
            ('GB', 'ENG') => ['London', 'Manchester', 'Birmingham'],
            ('GB', 'SCT') => ['Edinburgh', 'Glasgow', 'Aberdeen'],
            ('PH', null) => ['Manila', 'Cebu City', 'Davao City'],
            ('US', null) => ['New York City', 'Los Angeles', 'Chicago'],
            ('GB', null) => ['London', 'Manchester', 'Birmingham'],
            _ => <String>[],
          },
        }),
      );
      return;
    }

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
        if (options.method == 'PUT') {
          handler.resolve(_ok(options, {'success': true}));
        } else {
          // Shape satisfies auth, profile, and onboarding data sources.
          handler.resolve(
            _ok(options, {
              'id': '1',
              'email': 'ada@example.com',
              'name': 'Ada Lovelace',
              'country': '',
              'state': '',
              'city': '',
              'district': '',
              'roleType': <String>[],
              'token': 'mock-access-token',
              'refreshToken': 'mock-refresh-token',
              'bio': 'Building great things with Flutter.',
              'joinedAt': '2024-01-15T00:00:00.000Z',
            }),
          );
        }
      case ApiEndpoints.roleRequestsMine:
        handler.resolve(_ok(options, {'data': <Map<String, dynamic>>[]}));
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
      // Public browse data, so the Home hero's globe has pins and cards (and
      // the Home feed has items) with no backend. Same shapes as the real API:
      // events are `{ data: [...] }`, venues are `{ venues: [...] }`.
      case ApiEndpoints.eventsBrowse:
        handler.resolve(_ok(options, {'data': _mockEvents}));
      case ApiEndpoints.venues:
        handler.resolve(_ok(options, {'venues': <Map<String, dynamic>>[]}));
      default:
        handler.reject(_error(options, 404, 'Unknown endpoint: $path'));
    }
  }

  static const List<Map<String, Object?>> _mockEvents = [
    {
      'id': 'mock-manila-1',
      'name': 'Debut Manila',
      'category': 'birthday',
      'targetCity': 'Manila',
      'targetCountry': 'Philippines',
      'lat': 14.5995,
      'lng': 120.9842,
      'images': [
        {
          'url':
              'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=200&auto=format&fit=crop',
        },
      ],
    },
    {
      'id': 'mock-manila-2',
      'name': 'Rooftop Launch Night',
      'category': 'corporate',
      'targetCity': 'Manila',
      'targetCountry': 'Philippines',
      'lat': 14.5547,
      'lng': 121.0244,
    },
    {
      'id': 'mock-cebu-1',
      'name': 'Food Festival Cebu',
      'category': 'social',
      'targetCity': 'Cebu City',
      'targetCountry': 'Philippines',
      'lat': 10.3157,
      'lng': 123.8854,
    },
    {
      'id': 'mock-cebu-2',
      'name': 'Beachfront Wedding',
      'category': 'wedding',
      'targetCity': 'Cebu City',
      'targetCountry': 'Philippines',
      'lat': 10.3157,
      'lng': 123.8854,
    },
    {
      'id': 'mock-baguio-1',
      'name': 'Mountain Wedding Baguio',
      'category': 'wedding',
      'targetCity': 'Baguio',
      'targetCountry': 'Philippines',
      'lat': 16.4023,
      'lng': 120.5960,
    },
    {
      'id': 'mock-boracay-1',
      'name': 'Sunset Beach Party',
      'category': 'social',
      'targetCity': 'Boracay',
      'targetCountry': 'Philippines',
      'lat': 11.9674,
      'lng': 121.9248,
    },
  ];

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
