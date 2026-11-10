import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

Ticket _ticket({
  String status = 'confirmed',
  Duration startsIn = const Duration(days: 5),
  String? templateId,
  bool hasReview = false,
}) =>
    Ticket(
      id: 'b1',
      eventName: 'Sky Hall',
      startAt: DateTime.now().add(startsIn),
      endAt: DateTime.now().add(startsIn + const Duration(hours: 5)),
      status: status,
      ticketCode: 'FXP-1234',
      templateId: templateId,
      hasReview: hasReview,
    );

Widget _card(Ticket ticket) => ProviderScope(
      retry: (_, __) => null,
      overrides: [
        displayCurrencyProvider.overrideWithValue('PHP'),
        fxRatesProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: TicketCard(ticket: ticket)),
        ),
      ),
    );

void _size(WidgetTester tester, {double width = 800, double text = 1}) {
  tester.view
    ..physicalSize = Size(width, 2400)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

const _past = Duration(days: -3);

final Finder _changeText = find.text('Request a change');
final Finder _cancelText = find.text('Cancel booking');
final Finder _reviewText = find.text('Leave a review');
final Finder _rebookText = find.text('Book again');
final Finder _directionsText = find.byIcon(Icons.location_on_outlined);

void main() {
  group('actions by booking state', () {
    testWidgets('upcoming venue booking: change and cancel only', (
      tester,
    ) async {
      _size(tester);
      await tester.pumpWidget(_card(_ticket()));
      await tester.pump();

      expect(_changeText, findsOneWidget);
      expect(_cancelText, findsOneWidget);
      expect(_reviewText, findsNothing);
      expect(_rebookText, findsNothing);
    });

    testWidgets('upcoming event package: cancel, no change, no rebook', (
      tester,
    ) async {
      _size(tester);
      await tester.pumpWidget(_card(_ticket(templateId: 't1')));
      await tester.pump();

      expect(_cancelText, findsOneWidget);
      expect(_changeText, findsNothing);
      expect(_rebookText, findsNothing);
    });

    testWidgets('finished booking: review, nothing to cancel or change', (
      tester,
    ) async {
      _size(tester);
      await tester.pumpWidget(
        _card(_ticket(status: 'completed', startsIn: _past)),
      );
      await tester.pump();

      expect(_reviewText, findsOneWidget);
      expect(_cancelText, findsNothing);
      expect(_changeText, findsNothing);
    });

    testWidgets('finished event package: review and book again', (
      tester,
    ) async {
      _size(tester);
      await tester.pumpWidget(
        _card(_ticket(status: 'completed', startsIn: _past, templateId: 't1')),
      );
      await tester.pump();

      expect(_reviewText, findsOneWidget);
      expect(_rebookText, findsOneWidget);
    });

    testWidgets('a review already posted is not offered again', (tester) async {
      _size(tester);
      await tester.pumpWidget(
        _card(_ticket(status: 'completed', startsIn: _past, hasReview: true)),
      );
      await tester.pump();

      expect(_reviewText, findsNothing);
    });

    testWidgets('cancelled booking offers no booking actions', (tester) async {
      _size(tester);
      await tester.pumpWidget(_card(_ticket(status: 'cancelled')));
      await tester.pump();

      expect(_cancelText, findsNothing);
      expect(_changeText, findsNothing);
      expect(_reviewText, findsNothing);
    });
  });

  group('spacing', () {
    testWidgets('text actions sit clear of the Directions button', (
      tester,
    ) async {
      _size(tester);
      await tester.pumpWidget(_card(_ticket()));
      await tester.pump();

      // The Wallet | Directions row: the only Row with two Expanded tiles.
      final tiles = find.ancestor(
        of: _directionsText,
        matching: find.byWidgetPredicate(
          (w) => w is Row && w.children.whereType<Expanded>().length == 2,
        ),
      );
      final above = tester.getBottomLeft(tiles).dy;
      final button = find.ancestor(
        of: _changeText,
        matching: find.byType(TextButton),
      );
      final below = tester.getTopLeft(button).dy;
      expect(below - above, greaterThanOrEqualTo(12));
    });

    testWidgets('change and cancel do not touch each other', (tester) async {
      _size(tester);
      await tester.pumpWidget(_card(_ticket()));
      await tester.pump();

      final change = tester.getBottomLeft(_changeText).dy;
      final cancel = tester.getTopLeft(_cancelText).dy;
      expect(cancel - change, greaterThanOrEqualTo(12));
    });
  });

  group('small screens', () {
    for (final text in [1.0, 1.5, 2.0]) {
      testWidgets('every action fits at 320 px, text x$text', (tester) async {
        _size(tester, width: 320, text: text);
        await tester.pumpWidget(
          _card(_ticket()),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(_changeText, findsOneWidget);
        expect(_cancelText, findsOneWidget);
      });

      testWidgets('review and book again fit at 320 px, text x$text', (
        tester,
      ) async {
        _size(tester, width: 320, text: text);
        await tester.pumpWidget(
          _card(
            _ticket(status: 'completed', startsIn: _past, templateId: 't1'),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(_reviewText, findsOneWidget);
        expect(_rebookText, findsOneWidget);
      });
    }
  });
}
