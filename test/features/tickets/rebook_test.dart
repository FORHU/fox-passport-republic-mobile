import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Ticket _ticket({
  String status = 'completed',
  Duration startsIn = const Duration(days: -10),
  String? templateId = 'tpl-1',
  bool sample = false,
}) =>
    Ticket(
      id: 'b1',
      eventName: 'Garden Birthday',
      city: 'Cebu City',
      startAt: DateTime.now().add(startsIn),
      endAt: DateTime.now().add(startsIn + const Duration(hours: 5)),
      status: status,
      templateId: templateId,
      isSample: sample,
    );

void _bigScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Shows the card, with a stub for the event page that records what it got.
Future<List<Object?>> _pump(WidgetTester tester, Ticket ticket) async {
  final opened = <Object?>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: SingleChildScrollView(child: TicketCard(ticket: ticket)),
        ),
      ),
      GoRoute(
        path: '/event',
        builder: (_, state) {
          opened.add(state.extra);
          return const Scaffold(body: Text('EVENT PAGE'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        displayCurrencyProvider.overrideWithValue('PHP'),
        fxRatesProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
  return opened;
}

void main() {
  group('Ticket', () {
    Map<String, dynamic> booking(Object? event) => {
          'id': 'b1',
          'status': 'completed',
          'startAt': '2026-10-01T10:00:00.000Z',
          'endAt': '2026-10-01T14:00:00.000Z',
          'event': event,
        };

    test('remembers the event package it was booked from', () {
      final t = Ticket.fromBooking(
        booking({'name': 'Garden Birthday', 'templateId': 'tpl-9'}),
      );
      expect(t.templateId, 'tpl-9');
    });

    test('has none for a booking made straight on a venue', () {
      expect(
        Ticket.fromBooking(booking({'name': 'Sky Hall'})).templateId,
        isNull,
      );
      expect(
        Ticket.fromBooking(booking({'name': 'Sky Hall', 'templateId': null}))
            .templateId,
        isNull,
      );
    });
  });

  group('Book again', () {
    testWidgets('is offered on a finished or cancelled package booking', (
      tester,
    ) async {
      _bigScreen(tester);
      for (final t in [
        _ticket(),
        _ticket(status: 'cancelled', startsIn: const Duration(days: 5)),
        _ticket(status: 'confirmed', startsIn: const Duration(days: -3)),
      ]) {
        await _pump(tester, t);
        expect(find.text('Book again'), findsOneWidget, reason: t.status);
      }
    });

    testWidgets('is not offered while the booking is still live', (
      tester,
    ) async {
      _bigScreen(tester);
      for (final t in [
        _ticket(status: 'confirmed', startsIn: const Duration(days: 5)),
        _ticket(status: 'pending', startsIn: const Duration(days: 5)),
      ]) {
        await _pump(tester, t);
        expect(find.text('Book again'), findsNothing, reason: t.status);
      }
    });

    testWidgets('is not offered without a package, or for the sample', (
      tester,
    ) async {
      _bigScreen(tester);
      for (final t in [_ticket(templateId: null), _ticket(sample: true)]) {
        await _pump(tester, t);
        expect(find.text('Book again'), findsNothing);
      }
    });

    testWidgets('opens the same event package', (tester) async {
      _bigScreen(tester);
      final opened = await _pump(tester, _ticket());

      await tester.tap(find.text('Book again'));
      await tester.pumpAndSettle();

      expect(find.text('EVENT PAGE'), findsOneWidget);
      final item = opened.single! as CatalogItem;
      expect(item.id, 'tpl-1');
      expect(item.kind, CatalogKind.events);
      expect(item.title, 'Garden Birthday');
      expect(item.city, 'Cebu City');
    });
  });
}
