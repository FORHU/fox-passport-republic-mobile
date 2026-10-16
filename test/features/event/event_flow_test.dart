import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/booking/data/booking_repository.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/features/event/data/event_repository.dart';
import 'package:flutter_template/features/event/presentation/pages/event_detail_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const _item = CatalogItem(
  id: 'ev1',
  kind: CatalogKind.events,
  title: 'Garden Birthday',
  city: 'Cebu City',
  category: 'birthday',
);

const Map<String, Object> _json = {
  'id': 'ev1',
  'name': 'Garden Birthday',
  'description': 'A birthday in the garden.',
  'category': 'birthday',
  'targetCity': 'Cebu City',
  'targetState': 'Cebu',
  'owner': {'id': 'o', 'name': 'Ivan Dela Cruz'},
  'maxAttendees': 50,
  'currentAttendees': 10,
  'estimatedTotal': 21000,
  'platformFeeAmount': 1000,
  // No photo: a network image would keep a spinner animating forever.
  'images': <Object>[],
  'templateVenues': [
    {
      'id': 'tv1',
      'isOptional': false,
      'agreedPrice': '12000',
      'venue': {'name': 'Garden Hall'},
    },
  ],
  'templateAssets': [
    {
      'id': 'ta1',
      'isOptional': true,
      'agreedPrice': 5000,
      'asset': {'name': 'Sound system'},
    },
  ],
  'templateServices': [
    {
      'id': 'ts1',
      'isOptional': true,
      'agreedPrice': 3000,
      'service': {'name': 'Photographer'},
    },
  ],
};

void main() {
  group('EventPackage', () {
    final package = EventPackage.fromJson(_json);

    test('reads the items, the host and the limits', () {
      expect(package.name, 'Garden Birthday');
      expect(package.hostName, 'Ivan Dela Cruz');
      expect(package.spotsLeft, 40);
      expect(package.items.length, 3);
      expect(package.optionalItems.map((i) => i.name), [
        'Sound system',
        'Photographer',
      ]);
      expect(package.isPriced, isTrue);
    });

    test('takes the savings and the fee off when items are left out', () {
      // Estimate 21,000 with a 1,000 fee: a 20,000 package at 5%.
      final all = package.quote({});
      expect(all.package, 20000);
      expect(all.fee, 1000);
      expect(all.total, 21000);

      final lean = package.quote({'ta1'});
      expect(lean.package, 15000);
      expect(lean.fee, 750);
      expect(lean.total, 15750);
    });

    test('never goes below nothing', () {
      expect(
        package.quote({'ta1', 'ts1', 'tv1'}).package,
        12000,
        reason: 'a required item cannot be left out',
      );
    });

    test('an event with no price is not bookable', () {
      final empty = EventPackage.fromJson(const {
        'id': 'x',
        'name': 'Empty',
        'estimatedTotal': 0,
        'platformFeeAmount': 0,
      });
      expect(empty.isPriced, isFalse);
      expect(empty.quote({}).total, 0);
    });

    test('knows when it is full', () {
      final full = EventPackage.fromJson(
        Map<String, dynamic>.of(_json)
          ..['maxAttendees'] = 10
          ..['currentAttendees'] = 10,
      );
      expect(full.isFull, isTrue);
    });

    test('lists the left-out items of one kind for the request', () {
      expect(
        package.excludedOf(PackageItemKind.gear, {'ta1', 'ts1'}),
        ['ta1'],
      );
      expect(
        package.excludedOf(PackageItemKind.service, {'ta1', 'ts1'}),
        ['ts1'],
      );
    });
  });

  group('event detail', () {
    Future<GoRouter> open(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(800, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      EventBookingArgs? pushed;
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push(
                  RouteNames.eventDetail,
                  extra: _item,
                ),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.eventDetail,
            builder: (_, state) =>
                EventDetailPage(item: state.extra! as CatalogItem),
          ),
          GoRoute(
            path: RouteNames.book,
            builder: (_, state) {
              pushed = state.extra as EventBookingArgs?;
              return Scaffold(
                body: Text('BOOK ${pushed?.excluded.join(',')}'),
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventPackageProvider.overrideWith(
              (ref, item) async => EventPackage.fromJson(_json),
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
      return router;
    }

    testWidgets('shows what is in the package and its price', (tester) async {
      await open(tester);

      expect(find.text('Garden Birthday'), findsOneWidget);
      expect(find.text('BIRTHDAY'), findsOneWidget);
      expect(find.text('Hosted by Ivan Dela Cruz'), findsOneWidget);
      expect(find.text('40 spots left'), findsOneWidget);
      expect(find.text('Garden Hall'), findsOneWidget);
      expect(find.text('INCLUDED'), findsOneWidget);
      expect(find.text('Sound system'), findsOneWidget);
      expect(find.text('₱5,000'), findsOneWidget);
      expect(find.text('₱21,000'), findsOneWidget);
      expect(find.text('Choose a date'), findsOneWidget);
    });

    testWidgets('switching an optional item off lowers the price', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.text('₱15,750'), findsOneWidget);
      expect(find.text('1 item left out'), findsOneWidget);
    });

    testWidgets('booking carries the items that were left out', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();

      expect(find.text('BOOK ta1'), findsOneWidget);
    });
  });

  group('booking an event package', () {
    late _MockApi api;
    late BookingRepository repository;
    final package = EventPackage.fromJson(_json);

    setUp(() {
      api = _MockApi();
      repository = BookingRepository(api, StubPaymentGateway());
    });

    test('prices from the package, without asking the venue preview', () async {
      final price = await repository.price(
        BookingSelection(
          venue: _item,
          package: package,
          excluded: const {'ts1'},
          date: DateTime(2026, 10, 20),
        ),
      );

      expect(price.itemsTotal, 17000);
      expect(price.platformFeeAmount, 850);
      expect(price.totalAmount, 17850);
      verifyNever(() => api.get(any(), query: any(named: 'query')));
    });

    test('reads the days it is already booked', () async {
      when(
        () => api.get(
          ApiEndpoints.bookingsAvailability,
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'bookedDates': ['2026-10-24T00:00:00.000Z'],
          },
        },
      );

      final days = await repository.unavailableDates(
        _item,
        templateId: 'ev1',
        from: DateTime(2026, 10),
      );

      expect(days, isNotEmpty);
      verify(
        () => api.get(
          ApiEndpoints.bookingsAvailability,
          query: {'templateId': 'ev1'},
        ),
      ).called(1);
    });

    test('books from the template and charges the server total', () async {
      when(() => api.post(ApiEndpoints.bookingFromTemplate, any())).thenAnswer(
        (_) async => {
          'data': {
            'eventId': 'e1',
            'booking': {'id': 'b1', 'ticketCode': 'BKG-AAA'},
          },
        },
      );
      when(() => api.get(ApiEndpoints.bookingById('b1'))).thenAnswer(
        (_) async => {
          'data': {'totalAmount': '17999', 'ticketCode': 'BKG-AAA'},
        },
      );
      final selection = BookingSelection(
        venue: _item,
        package: package,
        excluded: const {'ta1'},
        guests: 4,
        date: DateTime(2026, 10, 20),
      );
      final price = await repository.price(selection);

      final receipt = await repository.create(selection, price);

      expect(receipt.id, 'b1');
      expect(receipt.reference, 'BKG-AAA');
      expect(
        receipt.totalAmount,
        17999,
        reason: 'the server total wins over the preview',
      );
      expect(receipt.needsApproval, isFalse);
      final sent = verify(
        () => api.post(
          ApiEndpoints.bookingFromTemplate,
          captureAny(),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sent['templateId'], 'ev1');
      expect(sent['guestCount'], 4);
      expect(sent['excludedAssetIds'], ['ta1']);
      expect(sent['excludedServiceIds'], isEmpty);
      expect(sent['excludedVenueIds'], isEmpty);
    });
  });

  test('the repository describes a sample row without the network', () async {
    final repo = EventRepository(_MockApi());
    final package = await repo.load(
      const CatalogItem(
        id: 'sample-event-1',
        kind: CatalogKind.events,
        title: 'Rooftop Launch Night',
        isSample: true,
      ),
    );

    expect(package.isSample, isTrue);
    expect(package.isPriced, isTrue);
    expect(package.optionalItems, isNotEmpty);
  });
}
