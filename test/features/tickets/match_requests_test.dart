import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/payments/payments_repository.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FailingGateway implements PaymentGateway {
  @override
  Future<String> pay({
    required String? clientSecret,
    required num amount,
    required String currency,
  }) async =>
      throw const PaymentsUnavailable();
}

class _OkGateway implements PaymentGateway {
  @override
  Future<String> pay({
    required String? clientSecret,
    required num amount,
    required String currency,
  }) async =>
      'pi_ok';
}

Map<String, dynamic> _row({
  String id = 'b1',
  String name = 'Match with Garden Birthday',
  String requestStatus = 'pending',
  String status = 'pending',
  num total = 0,
  List<Map<String, dynamic>> payments = const [],
}) =>
    {
      'id': id,
      'status': status,
      'guestCount': 40,
      'totalAmount': total,
      'startAt': '2026-12-20T10:00:00.000Z',
      'payments': payments,
      'event': {
        'id': 'e-$id',
        'name': name,
        'requestStatus': requestStatus,
        'host': {'id': 'f1', 'name': 'Maria Mayor'},
      },
    };

void main() {
  group('MatchRequestItem', () {
    test('reads a match and tells it from an ordinary booking', () {
      final item = MatchRequestItem.tryParse(_row())!;
      expect(item.style, 'Garden Birthday');
      expect(item.foxerName, 'Maria Mayor');
      expect(item.foxerId, 'f1');
      expect(item.guests, 40);

      expect(
        MatchRequestItem.tryParse(_row(name: 'Sky Hall Booking')),
        isNull,
      );
    });

    test('states follow the answer and the payment', () {
      MatchState of(Map<String, dynamic> row) =>
          MatchRequestItem.tryParse(row)!.state;

      expect(of(_row()), MatchState.waiting);
      expect(of(_row(requestStatus: 'approved')), MatchState.accepted);
      expect(
        of(_row(requestStatus: 'approved', status: 'confirmed')),
        MatchState.confirmed,
      );
      expect(
        of(
          _row(
            requestStatus: 'approved',
            payments: [
              {'status': 'paid'},
            ],
          ),
        ),
        MatchState.confirmed,
      );
      expect(of(_row(requestStatus: 'rejected')), MatchState.declined);
      expect(of(_row(status: 'cancelled')), MatchState.declined);
    });

    test('only an accepted request with a price needs paying', () {
      MatchRequestItem item(Map<String, dynamic> r) =>
          MatchRequestItem.tryParse(r)!;

      expect(
        item(_row(requestStatus: 'approved', total: 18000)).needsPayment,
        isTrue,
      );
      expect(item(_row(requestStatus: 'approved')).needsPayment, isFalse);
      expect(item(_row(total: 18000)).needsPayment, isFalse);
    });

    test('a declined request cannot be withdrawn', () {
      final declined = MatchRequestItem.tryParse(
        _row(requestStatus: 'rejected'),
      )!;
      expect(declined.canWithdraw, isFalse);
      expect(MatchRequestItem.tryParse(_row())!.canWithdraw, isTrue);
    });
  });

  group('payments', () {
    test('pays a booking: intent, gateway, then confirm with that intent',
        () async {
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.createPaymentIntent, any())).thenAnswer(
        (_) async => {
          'data': {'clientSecret': 'cs', 'paymentIntentId': 'pi_123'},
        },
      );
      when(() => api.post(ApiEndpoints.bookingConfirm('b1'), any()))
          .thenAnswer((_) async => {});

      await PaymentsRepository(api, _OkGateway()).payBooking(
        bookingId: 'b1',
        amount: 18000,
        currency: 'PHP',
      );

      verify(
        () => api.post(ApiEndpoints.bookingConfirm('b1'), {
          'amount': 18000,
          'method': 'stripe',
          'transactionId': 'pi_123',
        }),
      ).called(1);
    });

    test('nothing is confirmed when the card cannot be taken', () async {
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.createPaymentIntent, any()))
          .thenAnswer((_) async => {'data': <String, dynamic>{}});

      await expectLater(
        PaymentsRepository(api, _FailingGateway()).payBooking(
          bookingId: 'b1',
          amount: 18000,
          currency: 'PHP',
        ),
        throwsA(isA<PaymentsUnavailable>()),
      );

      verifyNever(() => api.post(ApiEndpoints.bookingConfirm('b1'), any()));
    });
  });

  group('Requests switch', () {
    List<Override> overrides(
      List<MatchRequestItem> items, {
      PaymentsRepository? payments,
    }) =>
        [
          availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
          upcomingTicketsProvider.overrideWith((ref) async => <Ticket>[]),
          pastTicketsProvider.overrideWith((ref) async => <Ticket>[]),
          myMatchRequestsProvider.overrideWith((ref) async => items),
          if (payments != null)
            paymentsRepositoryProvider.overrideWithValue(payments),
        ];

    Future<void> open(
      WidgetTester tester,
      List<Override> overrides,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TicketsPage(initialSegment: 'requests'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists each request with where it stands', (tester) async {
      await open(
        tester,
        overrides([
          MatchRequestItem.tryParse(_row())!,
          MatchRequestItem.tryParse(
            _row(
              id: 'b2',
              name: 'Match with Own idea',
              requestStatus: 'approved',
              total: 18000,
            ),
          )!,
          MatchRequestItem.tryParse(
            _row(id: 'b3', requestStatus: 'rejected', status: 'cancelled'),
          )!,
        ]),
      );

      expect(find.text('WAITING FOR REPLY'), findsOneWidget);
      expect(find.text('ACCEPTED'), findsOneWidget);
      expect(find.text('DECLINED'), findsOneWidget);
      expect(find.text('My own idea'), findsOneWidget);
      expect(find.text('₱18,000'), findsOneWidget);
      expect(find.text('Pay now'), findsOneWidget, reason: 'only the accepted');
      expect(
        find.text('Maria Mayor has your request and will reply soon.'),
        findsOneWidget,
      );
    });

    testWidgets('says so when there are none', (tester) async {
      await open(tester, overrides(const []));

      expect(
        find.text(
          'No requests yet. Ask a Foxer to match you from their profile.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Pay now says plainly when cards cannot be taken yet', (
      tester,
    ) async {
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.createPaymentIntent, any()))
          .thenAnswer((_) async => {'data': <String, dynamic>{}});
      await open(
        tester,
        overrides(
          [
            MatchRequestItem.tryParse(
              _row(requestStatus: 'approved', total: 18000),
            )!,
          ],
          payments: PaymentsRepository(api, _FailingGateway()),
        ),
      );

      await tester.tap(find.text('Pay now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Card payments in the app are coming soon.'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 4));
    });
  });
}
