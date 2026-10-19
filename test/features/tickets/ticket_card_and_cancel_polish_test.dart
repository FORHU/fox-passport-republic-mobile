import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _MockApi extends Mock implements ApiService {}

Ticket _ticket({
  String status = 'confirmed',
  Duration startsIn = const Duration(days: 5),
  bool sample = false,
}) =>
    Ticket(
      id: 'b1',
      eventName: 'Sky Hall',
      startAt: DateTime.now().add(startsIn),
      endAt: DateTime.now().add(startsIn + const Duration(hours: 5)),
      status: status,
      ticketCode: 'FXP-1234',
      isSample: sample,
    );

Widget _card(
  Ticket ticket, {
  List<Override> overrides = const [],
  String currency = 'PHP',
  FxRates? rates,
}) =>
    ProviderScope(
      // A failed load stays failed, so the error state can be seen.
      retry: (_, __) => null,
      overrides: [
        displayCurrencyProvider.overrideWithValue(currency),
        fxRatesProvider.overrideWith((ref) async => rates),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: TicketCard(ticket: ticket)),
        ),
      ),
    );

void _bigScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('QR code', () {
    testWidgets('is drawn for a confirmed booking that has not finished', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(_card(_ticket()));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('FXP-1234'), findsOneWidget);
    });

    testWidgets('is not drawn for a pending, cancelled, finished or past one', (
      tester,
    ) async {
      _bigScreen(tester);
      for (final ticket in [
        _ticket(status: 'pending'),
        _ticket(status: 'cancelled'),
        _ticket(status: 'completed'),
        _ticket(startsIn: const Duration(days: -2)),
      ]) {
        await tester.pumpWidget(_card(ticket));
        await tester.pump();
        expect(find.byType(QrImageView), findsNothing, reason: ticket.status);
      }
    });

    testWidgets('a cancelled booking does not show its code either', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(_card(_ticket(status: 'cancelled')));
      await tester.pump();

      expect(find.text('FXP-1234'), findsNothing);
    });

    testWidgets('a pending booking keeps its code as a reference', (
      tester,
    ) async {
      _bigScreen(tester);
      await tester.pumpWidget(_card(_ticket(status: 'pending')));
      await tester.pump();

      expect(find.text('FXP-1234'), findsOneWidget);
    });

    testWidgets('the sample ticket keeps its placeholder', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(_card(_ticket(sample: true)));
      await tester.pump();

      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    });
  });

  group('cancel sheet', () {
    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows amounts in the currency the user chose', (
      tester,
    ) async {
      _bigScreen(tester);
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.bookingCancelCheck('b1'))).thenAnswer(
        (_) async => {
          'data': {
            'eligible': true,
            'refundPercent': 50,
            'totalPaid': 1000,
            'estimatedRefund': 500,
          },
        },
      );

      await tester.pumpWidget(
        _card(
          _ticket(),
          overrides: [
            ticketsRepositoryProvider
                .overrideWithValue(TicketsRepository(api, 'u')),
          ],
          currency: 'USD',
          rates: const FxRates(
            base: 'PHP',
            rates: {'PHP': 1, 'USD': 0.02},
          ),
        ),
      );
      await tester.pump();
      await openSheet(tester);

      expect(find.text(r'$20'), findsOneWidget);
      expect(find.text(r'$10 (50%)'), findsOneWidget);
      expect(find.textContaining('₱'), findsNothing);
    });

    testWidgets('a failed quote can be retried', (tester) async {
      _bigScreen(tester);
      final api = _MockApi();
      var calls = 0;
      when(() => api.post(ApiEndpoints.bookingCancelCheck('b1'))).thenAnswer(
        (_) async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return {
            'data': {
              'eligible': true,
              'refundPercent': 100,
              'totalPaid': 1000,
              'estimatedRefund': 1000,
            },
          };
        },
      );

      await tester.pumpWidget(
        _card(
          _ticket(),
          overrides: [
            ticketsRepositoryProvider
                .overrideWithValue(TicketsRepository(api, 'u')),
          ],
        ),
      );
      await tester.pump();
      await openSheet(tester);

      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('₱1,000'), findsWidgets);
    });
  });
}
