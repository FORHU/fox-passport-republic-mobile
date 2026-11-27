import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/booking/data/booking_repository.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/features/booking/presentation/pages/booking_flow_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/policies/cancellation_terms.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const _venue = CatalogItem(
  id: 'sample-venue-1',
  kind: CatalogKind.venues,
  title: 'Sky Hall',
  city: 'Davao City',
  capacity: 200,
  price: 25000,
  billingRate: 'daily',
  isSample: true,
);

// Sample venues never reach the network, so the API is an unused mock. A real
// venue asks it for booked days; the mock answers nothing, so none are.
Widget _app({CatalogItem venue = _venue}) => ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(
          BookingRepository(_MockApi(), StubPaymentGateway()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookingFlowPage(venue: venue),
      ),
    );

void _bigScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 1800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  stalePaymentTests();

  group('BookingSelection', () {
    test('knows how many guests are over capacity', () {
      const s = BookingSelection(venue: _venue, guests: 220);
      expect(s.isOverCapacity, isTrue);
      expect(s.overCapacity, 20);
      expect(s.copyWith(guests: 200).isOverCapacity, isFalse);
    });

    test('books the whole local day', () {
      final s = BookingSelection(venue: _venue, date: DateTime(2026, 10, 17));
      expect(s.startAt, DateTime(2026, 10, 17));
      expect(s.endAt, DateTime(2026, 10, 17, 23, 59, 59));
    });

    test('a range runs from the first day to the end of the last', () {
      final s = const BookingSelection(venue: _venue)
          .withDates(DateTime(2026, 11, 20), DateTime(2026, 11, 22));
      expect(s.days, 3);
      expect(s.startAt, DateTime(2026, 11, 20));
      expect(s.endAt, DateTime(2026, 11, 22, 23, 59, 59));
      expect(s.dateLabel('en'), 'Fri 20 – Sun 22 Nov');
      // A new first day drops the old last day.
      expect(s.copyWith(date: DateTime(2026, 11, 27)).endDate, isNull);
    });
  });

  group('package price', () {
    test('a package costs its price for each day booked', () async {
      const package = EventPackage(
        id: 'p1',
        name: 'Social Night',
        estimatedTotal: 10500,
        platformFeeAmount: 500,
        isSample: true,
      );
      final repo = BookingRepository(_MockApi(), StubPaymentGateway());
      final one = const BookingSelection(venue: _venue, package: package)
          .withDates(DateTime(2026, 11, 20), null);
      final three =
          one.withDates(DateTime(2026, 11, 20), DateTime(2026, 11, 22));

      final p1 = await repo.price(one);
      final p3 = await repo.price(three);
      expect(p1.totalAmount, 10500);
      expect(p3.totalAmount, 31500);
      expect(p3.platformFeeAmount, 1500);
      expect(p3.days, 3);
    });
  });

  group('VenuePricing', () {
    test('reads the API numbers as they come, decimals as strings', () {
      final p = VenuePricing.fromJson(const {
        'itemsTotal': 25000,
        'platformFeeAmount': '1250',
        'discountAmount': 0,
        'totalAmount': 26250,
        'needsApproval': true,
        'extraGuests': 20,
      });
      expect(p.totalAmount, 26250);
      expect(p.platformFeeAmount, 1250);
      expect(p.needsApproval, isTrue);
      expect(p.isSample, isFalse);
    });
  });

  testWidgets('the guest count can be typed', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('guest-count'));
    await tester.enterText(field, '150');
    await tester.pump();
    expect(find.text('150 guests'), findsOneWidget);

    // Letters never get in.
    await tester.enterText(field, '15a');
    await tester.pump();
    expect(find.text('15 guests'), findsOneWidget);

    // Cleared and left: back to the count it still holds.
    await tester.enterText(field, '');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, '15');

    // The buttons still count from what was typed.
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('16 guests'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, '16');
  });

  testWidgets('a range is capped at 60 days', (tester) async {
    _bigScreen(tester);
    const open = CatalogItem(
      id: 'venue-open',
      kind: CatalogKind.venues,
      title: 'Open Hall',
      capacity: 200,
      price: 25000,
      billingRate: 'daily',
    );
    await tester.pumpWidget(_app(venue: open));
    await tester.pumpAndSettle();
    final next = find.byIcon(Icons.chevron_right_rounded);

    // The 1st of next month, then the 15th two months on: over 60 days.
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').first);
    await tester.pump();

    expect(find.text('You can book up to 60 days at a time.'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget); // The first day stays.

    // Within the cap it takes: the 1st of the month before, both ends counted.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    final withinCap = find.textContaining(RegExp(r'^(29|30|31|32) days$'));
    expect(withinCap, findsOneWidget);
  });

  testWidgets('a second, later day books every day between', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    expect(find.text('1 day'), findsOneWidget);

    await tester.tap(find.text('22').first);
    await tester.pumpAndSettle();
    expect(find.text('3 days'), findsOneWidget);
    // The 21st is covered: a band runs behind it, and the legend says so.
    final band = find.descendant(
      of: find.ancestor(
        of: find.text('21').first,
        matching: find.byType(Stack),
      ),
      matching: find.byKey(const ValueKey('band')),
    );
    expect(band, findsNWidgets(2));
    // Drawn, not just present: the band is nearly the day's full height.
    expect(tester.getSize(band.first).height, 40);
    expect(find.text('Covered'), findsOneWidget);

    // A third tap starts over from that day.
    await tester.tap(find.text('21').first);
    await tester.pumpAndSettle();
    expect(find.text('1 day'), findsOneWidget);

    // A range can't run over a booked day (the sample books the 24th and
    // 25th), so the 26th starts over instead.
    await tester.tap(find.text('26').first);
    await tester.pumpAndSettle();
    expect(find.text('1 day'), findsOneWidget);

    // An earlier day starts over too.
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('22').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // The sample price covers all three days.
    expect(find.textContaining('x 3 days'), findsOneWidget);
    expect(find.text('₱75,000'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dates, guests, review, then pay for a venue in capacity', (
    tester,
  ) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('When is it?'), findsOneWidget);
    expect(find.text('1 OF 3'), findsOneWidget);

    // Next is off until a day is picked. Day 20 is never a sample booked day.
    // Next month: every day in it is still ahead, whatever today is.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('How many guests?'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('Fits up to 200'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('₱25,000'), findsWidgets);
    expect(find.text('Service fee'), findsOneWidget);
    expect(find.text('₱26,250'), findsOneWidget);
    expect(find.text('SAMPLE AMOUNTS'), findsOneWidget);
    expect(find.text('Continue to payment'), findsOneWidget);

    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();

    expect(find.text('Pay ₱26,250'), findsOneWidget);
    expect(find.text('Card number'), findsOneWidget);
    // Card only: no Apple Pay or Google Pay buttons.
    expect(find.byIcon(Icons.apple), findsNothing);
    expect(find.byIcon(Icons.g_mobiledata_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // mobile#502: the citizen reads the venue's own refund terms before paying.
  group('the cancellation terms on the review', () {
    Future<void> toReview(WidgetTester tester, Widget app) async {
      _bigScreen(tester);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    String shown(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('booking-cancellation')))
        .data!;

    testWidgets("are the venue's own when it has them", (tester) async {
      await toReview(
        tester,
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(
              BookingRepository(_MockApi(), StubPaymentGateway()),
            ),
            venueCancellationProvider.overrideWith(
              (ref, venue) async => const CancellationTerms.flexible(
                refundPercent: 50,
                hoursBefore: 168,
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BookingFlowPage(venue: _venue),
          ),
        ),
      );

      expect(
        shown(tester),
        '50% refund if cancelled at least 7 days before the booking.',
      );
    });

    testWidgets('say non-refundable when it is', (tester) async {
      await toReview(
        tester,
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(
              BookingRepository(_MockApi(), StubPaymentGateway()),
            ),
            venueCancellationProvider.overrideWith(
              (ref, venue) async => const CancellationTerms.nonRefundable(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BookingFlowPage(venue: _venue),
          ),
        ),
      );

      expect(
        shown(tester),
        'Non-refundable: no refund if the booking is cancelled.',
      );
    });

    testWidgets('keep the general line when there are none to read', (
      tester,
    ) async {
      // A sample venue has no policy.
      await toReview(tester, _app());

      expect(shown(tester), 'Free cancellation for 48 hours.');
    });

    test('are read from the venue', () async {
      final api = _MockApi();
      when(() => api.get('/venues/v1')).thenAnswer(
        (_) async => {
          'venue': {
            'id': 'v1',
            'cancellationPolicy': {
              'name': 'Flexible',
              'rules': [
                {'hoursBeforeEvent': 48, 'refundPercent': 75},
              ],
            },
          },
        },
      );
      final terms =
          await BookingRepository(api, StubPaymentGateway()).cancellationTerms(
        const CatalogItem(id: 'v1', kind: CatalogKind.venues, title: 'Hall'),
      );
      expect(
        terms,
        const CancellationTerms.flexible(refundPercent: 75, hoursBefore: 48),
      );
    });
  });

  testWidgets('going over capacity warns and ends in a request, not a charge', (
    tester,
  ) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Next month: every day in it is still ahead, whatever today is.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 20; i++) {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    expect(find.text('220'), findsOneWidget);
    expect(
      find.text(
        '20 over capacity. The owner has to approve before you pay.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Request to book'), findsOneWidget);

    await tester.tap(find.text('Request to book'));
    await tester.pumpAndSettle();

    expect(find.text('Request sent'), findsOneWidget);
    expect(find.text('Waiting for the owner to confirm.'), findsOneWidget);
    expect(find.text('Amount if approved'), findsOneWidget);
    expect(find.text('Message the owner'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Records every booking it creates and never completes a payment.
class _FailingPayRepository extends BookingRepository {
  _FailingPayRepository({
    this.failure = const PaymentsUnavailable(),
    this.awaiting = 0,
  }) : super(_MockApi(), StubPaymentGateway());

  /// What paying throws: no card payments, or a sheet that was closed.
  final Exception failure;

  /// Suppliers asked first on each booking it creates.
  final int awaiting;

  final created = <BookingSelection>[];
  int payAttempts = 0;

  @override
  Future<Set<DateTime>> unavailableDates(
    CatalogItem venue, {
    required DateTime from,
    String? templateId,
  }) async =>
      {};

  @override
  Future<VenuePricing> price(BookingSelection s) async => const VenuePricing(
        itemsTotal: 25000,
        platformFeeAmount: 1250,
        totalAmount: 26250,
      );

  @override
  Future<BookingReceipt> create(BookingSelection s, VenuePricing p) async {
    created.add(s);
    return BookingReceipt(
      id: 'b${created.length}',
      reference: 'T${created.length}',
      totalAmount: p.totalAmount,
      currency: 'PHP',
      needsApproval: false,
      awaitingSuppliers: awaiting,
    );
  }

  @override
  Future<void> pay(BookingReceipt booking) async {
    payAttempts++;
    throw failure;
  }
}

void stalePaymentTests() {
  Future<_FailingPayRepository> reachPayStep(
    WidgetTester tester, {
    Exception failure = const PaymentsUnavailable(),
    int awaiting = 0,
  }) async {
    _bigScreen(tester);
    final repo = _FailingPayRepository(failure: failure, awaiting: awaiting);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookingFlowPage(venue: _venue),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Next month: every day in it is still ahead, whatever today is.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('closing the payment sheet says nothing was charged, no error',
      (tester) async {
    await reachPayStep(tester, failure: const PaymentCancelled());

    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pumpAndSettle();

    expect(
      find.text('Payment cancelled. You were not charged.'),
      findsOneWidget,
    );
    expect(
      find.text('Card payments in the app are coming soon.'),
      findsNothing,
    );
    // Still on the pay step, ready to try again.
    expect(find.textContaining('Pay ₱'), findsOneWidget);
  });

  testWidgets('retrying a failed payment reuses the same booking', (
    tester,
  ) async {
    final repo = await reachPayStep(tester);

    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
  });

  testWidgets('changing the guests after a failed payment books afresh', (
    tester,
  ) async {
    final repo = await reachPayStep(tester);

    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pumpAndSettle();
    expect(repo.created.single.guests, 200);

    // Back to the guests step, take one off, and pay again.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(2));
    expect(repo.created.last.guests, 199);
  });

  testWidgets('a booking with Suppliers to answer is not charged yet', (
    tester,
  ) async {
    final repo = await reachPayStep(tester, awaiting: 2);

    await tester.tap(find.textContaining('Pay ₱'));
    await tester.pumpAndSettle();

    expect(repo.created, hasLength(1));
    expect(repo.payAttempts, 0);
    expect(find.text('Waiting for Suppliers'), findsOneWidget);
    expect(
      find.textContaining('2 Suppliers in this package confirm first'),
      findsOneWidget,
    );
    expect(find.text('To pay once confirmed'), findsOneWidget);
    expect(find.text('View ticket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
