import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/features/foxer/presentation/pages/foxer_profile_page.dart';
import 'package:flutter_template/features/foxer/presentation/pages/match_request_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/foxers/foxer_profile.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import '../../support/future_day.dart';

class _MockApi extends Mock implements ApiService {}

const _row = CatalogItem(
  id: 'f1',
  kind: CatalogKind.foxers,
  title: 'Maria Mayor',
  city: 'Davao City',
);

const _json = <String, dynamic>{
  'id': 'f1',
  'name': 'Maria Mayor',
  'imgId': null,
  'city': 'Davao City',
  'state': 'Davao del Sur',
  'roleType': ['eventFoxer'],
  'identityVerifiedAt': '2026-01-01T00:00:00.000Z',
  'avgRating': '4.8',
  'reviewCount': 12,
  'eventTemplates': [
    {'id': 't1', 'name': 'Garden Birthday', 'category': 'birthday'},
  ],
  'venues': [
    {
      'id': 'v1',
      'name': 'Sky Hall',
      'price': '25000',
      'billingRate': 'daily',
      'capacity': 200,
      'images': [
        {'url': 'https://example.com/a.jpg'},
      ],
    },
  ],
  'assets': <Object>[],
  'services': [
    {'id': 's1', 'name': 'Photographer', 'price': 6000, 'billingRate': 'daily'},
  ],
};

List<Override> _overrides(FoxerProfile profile, {ApiService? api}) => [
      foxerProfileProvider.overrideWith((ref, item) async => profile),
      if (api != null)
        foxerRepositoryProvider.overrideWithValue(FoxerRepository(api)),
      displayCurrencyProvider.overrideWithValue('PHP'),
      fxRatesProvider.overrideWith((ref) async => null),
      profileLocationProvider
          .overrideWith((ref) async => const ProfileLocation()),
    ];

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  group('FoxerProfile', () {
    final profile = FoxerProfile.fromJson(_json);

    test('reads the person, their rating and where they are', () {
      expect(profile.name, 'Maria Mayor');
      expect(profile.verified, isTrue);
      expect(profile.rating, 4.8);
      expect(profile.reviewCount, 12);
      expect(profile.place, 'Davao City, Davao del Sur');
      expect(profile.roles, ['eventFoxer']);
    });

    test('turns everything they offer into catalog rows of the right kind', () {
      expect(profile.offers.map((o) => o.kind), [
        CatalogKind.events,
        CatalogKind.venues,
        CatalogKind.services,
      ]);
      final hall = profile.offers.firstWhere((o) => o.id == 'v1');
      expect(hall.price, 25000);
      expect(hall.capacity, 200);
      expect(hall.imageUrl, 'https://example.com/a.jpg');
      expect(hall.host, 'Maria Mayor');
    });

    test('a bare Foxer has nothing optional', () {
      final bare = FoxerProfile.fromJson(const {'id': 'x', 'name': 'Bare'});
      expect(bare.offers, isEmpty);
      expect(bare.verified, isFalse);
      expect(bare.rating, isNull);
    });
  });

  group('FoxerRepository', () {
    test('asks the API for the whole profile', () async {
      final api = _MockApi();
      when(() => api.get(ApiEndpoints.foxerById('f1')))
          .thenAnswer((_) async => {'data': _json});

      final loaded = await FoxerRepository(api).load(_row);

      expect(loaded.name, 'Maria Mayor');
    });

    test('a sample row is described locally, without the network', () async {
      final api = _MockApi();
      final loaded = await FoxerRepository(api).load(
        const CatalogItem(
          id: 'sample-foxer-1',
          kind: CatalogKind.foxers,
          title: 'Rico Rival',
          isSample: true,
        ),
      );

      expect(loaded.isSample, isTrue);
      expect(loaded.offers, isNotEmpty);
      verifyZeroInteractions(api);
    });

    test('sends a match with the date at 6pm and no price', () async {
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.matches, any()))
          .thenAnswer((_) async => {'bookingId': 'b', 'clientSecret': null});

      await FoxerRepository(api).sendMatch(
        MatchRequest(
          foxerId: 'f1',
          date: DateTime(2026, 10, 20),
          guests: 30,
          style: 'Garden Birthday',
          message: '  Something warm  ',
        ),
        isSample: false,
      );

      final sent = verify(
        () => api.post(ApiEndpoints.matches, captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(sent['foxerId'], 'f1');
      expect(sent['style'], 'Garden Birthday');
      expect(sent['guestCount'], 30);
      expect(sent['requestContent'], 'Something warm');
      expect(sent.containsKey('totalAmount'), isFalse);
      expect(
        DateTime.parse(sent['date'] as String).toLocal(),
        DateTime(2026, 10, 20, 18),
      );
    });

    test('"my own idea" is sent as the API default', () async {
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.matches, any()))
          .thenAnswer((_) async => {});

      await FoxerRepository(api).sendMatch(
        MatchRequest(foxerId: 'f1', date: DateTime(2026, 10, 20), guests: 2),
        isSample: false,
      );

      final sent = verify(
        () => api.post(ApiEndpoints.matches, captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(sent['style'], 'Own idea');
      expect(sent.containsKey('requestContent'), isFalse);
    });

    test('a sample Foxer sends nothing', () async {
      final api = _MockApi();
      await FoxerRepository(api).sendMatch(
        MatchRequest(foxerId: 'f', date: DateTime(2026, 10, 20), guests: 2),
        isSample: true,
      );
      verifyZeroInteractions(api);
    });
  });

  group('profile page', () {
    testWidgets('shows the Foxer, their rating and what they offer', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          const FoxerProfilePage(item: _row),
          _overrides(
            FoxerProfile.fromJson(
              Map<String, dynamic>.of(_json)..['venues'] = <Object>[],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Maria Mayor'), findsWidgets);
      expect(find.text('Event Foxer'), findsOneWidget);
      expect(find.text('Davao City, Davao del Sur'), findsOneWidget);
      expect(find.text('4.8 · 12 reviews'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('Match me'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Garden Birthday'), findsOneWidget);
      expect(find.text('Photographer'), findsOneWidget);
      expect(find.text('₱6,000/day'), findsOneWidget);
    });

    testWidgets('Match me opens the request form for this Foxer', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      CatalogItem? sentTo;
      final router = GoRouter(
        initialLocation: RouteNames.foxer,
        routes: [
          GoRoute(
            path: RouteNames.foxer,
            builder: (_, __) => const FoxerProfilePage(item: _row),
          ),
          GoRoute(
            path: RouteNames.match,
            builder: (_, state) {
              sentTo = state.extra as CatalogItem?;
              return const Scaffold(body: Text('MATCH FORM'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            FoxerProfile.fromJson(
              Map<String, dynamic>.of(_json)..['venues'] = <Object>[],
            ),
          ),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Match me'));
      await tester.pumpAndSettle();

      expect(find.text('MATCH FORM'), findsOneWidget);
      expect(sentTo?.id, 'f1');
    });
  });

  group('match request page', () {
    testWidgets('needs a day, then sends the request and confirms', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.matches, any()))
          .thenAnswer((_) async => {'bookingId': 'b', 'clientSecret': null});

      await tester.pumpWidget(
        _app(
          const MatchRequestPage(item: _row),
          _overrides(FoxerProfile.fromJson(_json), api: api),
        ),
      );
      await tester.pumpAndSettle();

      ElevatedButton send() =>
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(send().onPressed, isNull, reason: 'no day chosen yet');
      // The guests stepper's icon-only buttons say what they do.
      expect(find.byTooltip('Decrease How many guests?'), findsOneWidget);
      expect(find.byTooltip('Increase How many guests?'), findsOneWidget);
      expect(find.text('Garden Birthday'), findsOneWidget);
      expect(find.text('My own idea'), findsOneWidget);

      await tester.tap(find.text('Garden Birthday'));
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tapFutureDay(tester);
      await tester.pumpAndSettle();
      expect(send().onPressed, isNotNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final sent = verify(
        () => api.post(ApiEndpoints.matches, captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(sent['style'], 'Garden Birthday');
      expect(sent['guestCount'], 3);
      expect(find.text('Request sent'), findsOneWidget);
      expect(
        find.text(
          'Maria Mayor will get back to you. '
          'You will be notified when they respond.',
        ),
        findsOneWidget,
      );
    });
  });
}
