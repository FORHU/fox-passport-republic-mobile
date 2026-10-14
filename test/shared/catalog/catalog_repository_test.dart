import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/config/environment.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late CatalogRepository repository;

  setUp(() {
    AppConfig.instance = const AppConfig.dev();
    api = _MockApiService();
    repository = CatalogRepository(api);
  });

  test('returns an empty result for a real API with no venues', () async {
    when(
      () => api.get(
        ApiEndpoints.venues,
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => {'venues': <Object>[]});

    final result = await repository.fetch(CatalogKind.venues);

    expect(result.items, isEmpty);
    expect(result.isSample, isFalse);
  });

  test('does not replace API failures with sample catalog items', () async {
    const failure = NetworkException();
    when(
      () => api.get(
        ApiEndpoints.venues,
        query: any(named: 'query'),
      ),
    ).thenThrow(failure);

    await expectLater(
      repository.fetch(CatalogKind.venues),
      throwsA(same(failure)),
    );
  });

  test('uses sample catalog items only when mock mode is enabled', () async {
    AppConfig.instance = const AppConfig.dev(useMock: true);
    when(
      () => api.get(
        ApiEndpoints.venues,
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => {'venues': <Object>[]});

    final result = await repository.fetch(CatalogKind.venues);

    expect(result.isSample, isTrue);
  });

  test('browses services and filters query results locally', () async {
    when(
      () => api.get(
        ApiEndpoints.servicesBrowse,
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': [
          {'id': 'service-1', 'name': 'Catering service', 'city': 'Manila'},
          {'id': 'service-2', 'name': 'DJ set', 'city': 'Cebu City'},
        ],
        'pagination': {'total': 2},
      },
    );

    final result = await repository.fetch(
      CatalogKind.services,
      query: 'catering',
    );

    expect(result.items.map((item) => item.id), ['service-1']);
    expect(result.total, 1);
  });

  group('narrowing to the user area', () {
    test('venues in a city use the list search, which matches the city',
        () async {
      when(
        () => api.get(ApiEndpoints.venues, query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'venues': [
            {'id': 'v1', 'name': 'Sky Hall', 'city': 'Davao City'},
          ],
        },
      );

      final result = await repository.fetch(
        CatalogKind.venues,
        city: 'Davao City',
      );

      expect(result.items.single.id, 'v1');
      final query = verify(
        () => api.get(ApiEndpoints.venues, query: captureAny(named: 'query')),
      ).captured.single as Map<String, dynamic>;
      expect(query['search'], 'Davao City');
    });

    test('Foxers in a city use the API city filter', () async {
      when(
        () => api.get(ApiEndpoints.foxers, query: any(named: 'query')),
      ).thenAnswer((_) async => {'data': <Object>[]});

      await repository.fetch(CatalogKind.foxers, city: 'Davao City');

      final query = verify(
        () => api.get(ApiEndpoints.foxers, query: captureAny(named: 'query')),
      ).captured.single as Map<String, dynamic>;
      expect(query['city'], 'Davao City');
    });

    test('a position asks which venues cover it', () async {
      when(
        () => api.get(ApiEndpoints.venuesNear, query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'venues': [
            {'id': 'v9', 'name': 'Harbour Hall'},
          ],
        },
      );

      final result = await repository.fetch(
        CatalogKind.venues,
        lat: 7.19,
        lng: 125.45,
        city: 'Davao City',
      );

      expect(result.items.single.id, 'v9');
      final query = verify(
        () => api.get(
          ApiEndpoints.venuesNear,
          query: captureAny(named: 'query'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(query, {'lat': 7.19, 'lng': 125.45});
    });

    test('when no venue covers the position it falls back to the city',
        () async {
      when(
        () => api.get(ApiEndpoints.venuesNear, query: any(named: 'query')),
      ).thenAnswer((_) async => {'venues': <Object>[]});
      when(
        () => api.get(ApiEndpoints.venues, query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'venues': [
            {'id': 'v1', 'name': 'Sky Hall', 'city': 'Davao City'},
          ],
        },
      );

      final result = await repository.fetch(
        CatalogKind.venues,
        lat: 7.19,
        lng: 125.45,
        city: 'Davao City',
      );

      expect(result.items.single.id, 'v1');
    });

    test('an empty narrowed list is not padded with samples', () async {
      AppConfig.instance = const AppConfig(
        environment: Environment.dev,
        appName: 'test',
        baseUrl: 'http://localhost',
        useMock: true,
      );
      when(
        () => api.get(ApiEndpoints.venues, query: any(named: 'query')),
      ).thenAnswer((_) async => {'venues': <Object>[]});

      final result = await repository.fetch(
        CatalogKind.venues,
        city: 'Nowhere',
      );

      expect(result.items, isEmpty);
    });
  });
}
