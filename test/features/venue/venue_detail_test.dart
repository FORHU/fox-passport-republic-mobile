import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/venue/data/venue_repository.dart';
import 'package:flutter_template/features/venue/domain/venue_detail.dart';
import 'package:flutter_template/features/venue/presentation/pages/venue_detail_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const _row = CatalogItem(
  id: 'v1',
  kind: CatalogKind.venues,
  title: 'averie',
  city: 'Baguio',
  capacity: 150,
  price: 15000,
  billingRate: 'daily',
);

const _json = <String, dynamic>{
  'id': 'v1',
  'name': 'averie',
  'description': 'sa bahay ni averie',
  'category': 'outdoor',
  'address': 'otek st',
  'city': 'Baguio',
  'state': 'Benguet',
  'capacity': 150,
  'price': '15000',
  'billingRate': 'daily',
  'images': <Object>[],
  'mayor': {'name': 'Mayor Santos'},
  'spaceType': <String>[],
  'inclusions': [
    {'name': 'LED Screen', 'icon': 'monitor'},
    {'name': 'PA Sound System', 'icon': 'speaker'},
  ],
  'amenities': ['Air conditioning'],
  'policies': ['No smoking indoors'],
  'parkingInformation': 'Free for 20 cars',
};

void main() {
  group('VenueDetail', () {
    test('reads the API venue, decimals as strings included', () {
      final v = VenueDetail.fromJson(_json);

      expect(v.name, 'averie');
      expect(v.price, 15000);
      expect(v.capacity, 150);
      expect(v.place, 'Baguio, Benguet');
      expect(v.hostName, 'Mayor Santos');
      expect(v.inclusions, ['LED Screen', 'PA Sound System']);
      expect(v.parking, 'Free for 20 cars');
      expect(v.hasGoodToKnow, isTrue);
    });

    test('a bare venue has nothing optional', () {
      final v = VenueDetail.fromJson(const {'id': 'x', 'name': 'Bare'});
      expect(v.inclusions, isEmpty);
      expect(v.hasGoodToKnow, isFalse);
      expect(v.place, isEmpty);
    });
  });

  test('the repository unwraps { venue } and describes samples locally',
      () async {
    final api = _MockApi();
    when(() => api.get(ApiEndpoints.venueById('v1')))
        .thenAnswer((_) async => {'venue': _json});
    final repo = VenueRepository(api);

    expect((await repo.load(_row)).name, 'averie');

    final sample = await repo.load(
      const CatalogItem(
        id: 'sample-venue-1',
        kind: CatalogKind.venues,
        title: 'Sky Hall',
        isSample: true,
      ),
    );
    expect(sample.isSample, isTrue);
    verifyNever(() => api.get(ApiEndpoints.venueById('sample-venue-1')));
  });

  testWidgets('shows the venue and Book now carries it to the booking flow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    CatalogItem? booked;
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  context.push(RouteNames.venueDetail, extra: _row),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.venueDetail,
          builder: (_, state) =>
              VenueDetailPage(item: state.extra! as CatalogItem),
        ),
        GoRoute(
          path: RouteNames.book,
          builder: (_, state) {
            booked = state.extra as CatalogItem?;
            return const Scaffold(body: Text('BOOKING'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          venueDetailProvider.overrideWith(
            (ref, item) async => VenueDetail.fromJson(_json),
          ),
          displayCurrencyProvider.overrideWithValue('PHP'),
          fxRatesProvider.overrideWith((ref) async => null),
          profileLocationProvider
              .overrideWith((ref) async => const ProfileLocation()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('averie'), findsOneWidget);
    expect(find.text('OUTDOOR'), findsOneWidget);
    expect(find.text('Baguio, Benguet'), findsOneWidget);
    expect(find.text('Up to 150 guests'), findsOneWidget);
    expect(find.text('LED Screen'), findsOneWidget);
    expect(find.text('Air conditioning'), findsOneWidget);
    expect(find.text('No smoking indoors'), findsOneWidget);
    expect(find.text('Free for 20 cars'), findsOneWidget);
    expect(find.text('₱15,000/day'), findsOneWidget);

    await tester.tap(find.text('Book now'));
    await tester.pumpAndSettle();

    expect(find.text('BOOKING'), findsOneWidget);
    expect(booked?.id, 'v1');
    expect(booked?.capacity, 150);
  });
}
