import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/config/environment.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/l10n/generated/app_localizations_en.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
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
    test('venues send city, price, capacity, and sort filters to the API',
        () async {
      when(
        () => api.get(ApiEndpoints.venues, query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'venues': [
            {
              'id': 'v1',
              'name': 'Sky Hall',
              'city': 'Davao City',
              'price': 25000,
              'capacity': 200,
            },
          ],
        },
      );

      final result = await repository.fetch(
        CatalogKind.venues,
        city: 'Davao City',
        minPrice: 10000,
        maxPrice: 30000,
        minCapacity: 100,
        sortBy: 'price_asc',
      );

      expect(result.items.single.id, 'v1');
      final query = verify(
        () => api.get(ApiEndpoints.venues, query: captureAny(named: 'query')),
      ).captured.single as Map<String, dynamic>;
      expect(query['city'], 'Davao City');
      expect(query['minPrice'], 10000);
      expect(query['maxPrice'], 30000);
      expect(query['minCapacity'], 100);
      expect(query['sortBy'], 'price_asc');
    });

    test('Foxers by specialty send the catalog slug, and nobody else does',
        () async {
      when(
        () => api.get(any(), query: any(named: 'query')),
      ).thenAnswer((_) async => {'data': <Object>[]});

      final foxers = await repository.fetch(
        CatalogKind.foxers,
        specialty: 'photography',
      );
      await repository.fetch(CatalogKind.venues, specialty: 'photography');

      expect(foxers.isSample, isFalse);
      final queries = verify(
        () => api.get(any(), query: captureAny(named: 'query')),
      ).captured.cast<Map<String, dynamic>>();
      expect(queries.first['specialty'], 'photography');
      expect(queries.last.containsKey('specialty'), isFalse);
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

  test('lists events from the published package browse (mobile#416)', () async {
    when(
      () => api.get(ApiEndpoints.eventsBrowse, query: any(named: 'query')),
    ).thenAnswer(
      (_) async => {
        'data': [
          {
            'id': 't1',
            'name': 'Garden Party',
            'targetCity': 'Baguio City',
            'price': 5000,
          },
          {
            'id': 't2',
            'name': 'Budget Picnic',
            'targetCity': 'Baguio City',
            'price': 1000,
          },
        ],
        'pagination': {'total': 2},
      },
    );

    // A package has no date or guest count: those filters must not drop it.
    final result = await repository.fetch(
      CatalogKind.events,
      city: 'Baguio',
      minPrice: 3000,
      maxPrice: 6000,
      minCapacity: 20,
      fromDate: DateTime(2026, 10, 31),
      toDate: DateTime(2026, 11, 2),
      sortBy: 'date_asc',
    );

    expect(result.items.map((e) => e.id), ['t1']);
    verifyNever(
      () => api.get(
        ApiEndpoints.publicEventsBrowse,
        query: any(named: 'query'),
      ),
    );
    final query = verify(
      () => api.get(
        ApiEndpoints.eventsBrowse,
        query: captureAny(named: 'query'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(query['city'], 'Baguio');
    expect(query['maxPrice'], 6000);
    for (final key in const [
      'minPrice',
      'minCapacity',
      'sortBy',
      'fromDate',
      'toDate',
    ]) {
      expect(query.containsKey(key), isFalse, reason: key);
    }
  });

  test('an event card names its venue with the city (api#511)', () {
    final item = CatalogRepository.parse(CatalogKind.events, {
      'id': 't1',
      'name': 'Garden Party',
      'targetCity': 'Baguio City',
      'templateVenues': [
        {
          'venue': {'name': 'Sky Hall', 'city': 'Baguio City'},
        },
      ],
    });

    expect(item?.venueName, 'Sky Hall');
    expect(
      catalogSubtitle(AppLocalizationsEn(), item!),
      'Sky Hall · Baguio City',
    );
  });

  test('an event without a venue name shows the city alone', () {
    final item = CatalogRepository.parse(CatalogKind.events, {
      'id': 't1',
      'name': 'Garden Party',
      'targetCity': 'Baguio City',
    });

    expect(item?.venueName, isNull);
    expect(catalogSubtitle(AppLocalizationsEn(), item!), 'Baguio City');
  });

  test('one event package it cannot read does not take the list down',
      () async {
    when(
      () => api.get(
        ApiEndpoints.eventsBrowse,
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => {
        'success': true,
        'data': [
          {'id': 'e1', 'name': 'Birthday', 'targetCity': 'Davao City'},
          // A capacity that is text, not a number, which the parser rejects.
          {'id': 'e2', 'name': 'Broken', 'guestCount': 'many'},
          {'id': 'e3', 'name': 'Reunion', 'targetCity': 'Manila'},
        ],
      },
    );

    final result = await repository.fetch(CatalogKind.events);

    expect(result.items.map((i) => i.id), ['e1', 'e3']);
  });
}
