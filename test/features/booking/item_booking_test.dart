import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/booking/data/item_booking_repository.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/features/booking/presentation/pages/item_booking_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/payments/payments_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../support/future_day.dart';

class _MockApi extends Mock implements ApiService {}

const _gear = CatalogItem(
  id: 'asset-1',
  kind: CatalogKind.gear,
  title: 'PA system',
  price: 1000,
  billingRate: 'daily',
);
const _service = CatalogItem(
  id: 'svc-1',
  kind: CatalogKind.services,
  title: 'Wedding photographer',
  price: 8000,
);
const _sample = CatalogItem(
  id: 'sample-gear',
  kind: CatalogKind.gear,
  title: 'Sample speaker',
  price: 500,
  billingRate: 'daily',
  isSample: true,
);

void main() {
  late _MockApi api;
  late ItemBookingRepository repo;

  setUp(() {
    AppConfig.instance = const AppConfig.prod();
    api = _MockApi();
    repo = ItemBookingRepository(api, StubPaymentGateway());
  });

  test('gear is blocked only on days where every unit is out', () async {
    when(
      () => api.get(any(), query: any(named: 'query')),
    ).thenAnswer(
      (_) async => {
        'data': {
          'totalQty': 2,
          'bookedRanges': [
            {
              'startDate': '2030-01-10',
              'endDate': '2030-01-11',
              'bookedQty': 1,
            },
            {
              'startDate': '2030-01-11',
              'endDate': '2030-01-11',
              'bookedQty': 1,
            },
          ],
        },
      },
    );
    final blocked = await repo.blockedDays(_gear);
    expect(blocked, {DateTime(2030, 1, 11)});
  });

  test('a service is blocked on booked and travel days', () async {
    when(
      () => api.get(any(), query: any(named: 'query')),
    ).thenAnswer(
      (_) async => {
        'data': {
          'bookedDates': ['2030-02-01'],
          'travelBlockedDates': ['2030-02-02'],
        },
      },
    );
    final blocked = await repo.blockedDays(_service, location: 'Davao');
    expect(blocked, {DateTime(2030, 2), DateTime(2030, 2, 2)});
  });

  test('gear prices over the days chosen and books delivery', () async {
    when(
      () => api.get(any(), query: any(named: 'query')),
    ).thenAnswer(
      (_) async => {
        'data': {
          'itemsTotal': 3000,
          'discountAmount': 0,
          'platformFeeAmount': 150,
          'totalAmount': 3150,
        },
      },
    );
    when(() => api.post(any(), any())).thenAnswer(
      (_) async => {
        'data': {'id': 'b1', 'ticketCode': 'TKT1', 'totalAmount': '3150'},
      },
    );
    final request = ItemBookingRequest(
      item: _gear,
      start: DateTime(2030, 3, 5),
      days: 3,
      quantity: 2,
      delivery: true,
      address: '1 Main St',
    );
    expect(request.endAt, DateTime(2030, 3, 7, 23, 59, 59));

    final price = await repo.price(request);
    expect(price.totalAmount, 3150);
    final query = verify(
      () => api.get(any(), query: captureAny(named: 'query')),
    ).captured.single as Map;
    expect(query['assetId'], 'asset-1');
    expect(query['quantity'], 2);

    final receipt = await repo.create(request, price);
    expect(receipt.id, 'b1');
    expect(receipt.reference, 'TKT1');
    expect(receipt.totalAmount, 3150);
    final body =
        verify(() => api.post(any(), captureAny())).captured.single as Map;
    expect(body['fulfillmentType'], 'delivery');
    expect(body['deliveryAddress'], '1 Main St');
  });

  test('a service books with its location and no end for one day', () async {
    when(() => api.post(any(), any())).thenAnswer(
      (_) async => {
        'data': {'id': 's1'},
      },
    );
    final request = ItemBookingRequest(
      item: _service,
      start: DateTime(2030, 3, 5),
      days: 1,
      location: 'Davao City',
    );
    await repo.create(
      request,
      const VenuePricing(
        itemsTotal: 8000,
        platformFeeAmount: 400,
        totalAmount: 8400,
      ),
    );
    final body =
        verify(() => api.post(any(), captureAny())).captured.single as Map;
    expect(body['serviceId'], 'svc-1');
    expect(body['location'], 'Davao City');
    expect(body.containsKey('endDate'), isFalse);
  });

  test('a request equals another with the same choices, not a changed one', () {
    final a =
        ItemBookingRequest(item: _gear, start: DateTime(2030, 3, 5), days: 2);
    final same =
        ItemBookingRequest(item: _gear, start: DateTime(2030, 3, 5), days: 2);
    final longer =
        ItemBookingRequest(item: _gear, start: DateTime(2030, 3, 5), days: 3);
    expect(a, same);
    expect(a, isNot(longer));
  });

  testWidgets('the steppers and month arrows say what they do', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [itemBookingRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ItemBookingPage(item: _sample),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Previous month'), findsOneWidget);
    expect(find.byTooltip('Next month'), findsOneWidget);
    // Gear has both a days and a quantity stepper.
    expect(find.byTooltip('Decrease How many days?'), findsOneWidget);
    expect(find.byTooltip('Increase How many days?'), findsOneWidget);
    expect(find.byTooltip('Decrease How many?'), findsOneWidget);
    expect(find.byTooltip('Increase How many?'), findsOneWidget);
  });

  testWidgets('a sample item shows its price once a day is picked', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemBookingRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ItemBookingPage(item: _sample),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample speaker'), findsOneWidget);
    expect(find.text('Pick a date.'), findsOneWidget);

    await tapFutureDay(tester);
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Sample amounts'), findsOneWidget);
  });
}
