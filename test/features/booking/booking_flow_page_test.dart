import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/booking/data/booking_repository.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/features/booking/presentation/pages/booking_flow_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
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

// Sample venues never reach the network, so the API is an unused mock.
Widget _app() => ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(
          BookingRepository(_MockApi(), StubPaymentGateway()),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookingFlowPage(venue: _venue),
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
    expect(find.text('Or pay by card'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  _FailingPayRepository() : super(_MockApi(), StubPaymentGateway());

  final created = <BookingSelection>[];

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
    );
  }

  @override
  Future<void> pay(BookingReceipt booking) async =>
      throw const PaymentsUnavailable();
}

void stalePaymentTests() {
  Future<_FailingPayRepository> reachPayStep(WidgetTester tester) async {
    _bigScreen(tester);
    final repo = _FailingPayRepository();
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
}
