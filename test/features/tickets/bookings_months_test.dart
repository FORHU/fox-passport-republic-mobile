import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

Ticket _ticket(String id, String name, DateTime start, {String? status}) =>
    Ticket(
      id: id,
      eventName: name,
      startAt: start,
      endAt: start.add(const Duration(hours: 5)),
      status: status ?? 'confirmed',
      ticketCode: 'FXP-$id',
    );

Widget _app({List<Ticket> upcoming = const [], List<Ticket> past = const []}) {
  return ProviderScope(
    overrides: [
      availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
      upcomingTicketsProvider.overrideWith((ref) async => upcoming),
      pastTicketsProvider.overrideWith((ref) async => past),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TicketsPage(),
    ),
  );
}

void main() {
  void phone(WidgetTester tester, {double width = 800}) {
    tester.view
      ..physicalSize = Size(width, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('a booking this month sits under This month with its date', (
    tester,
  ) async {
    phone(tester);
    final now = DateTime.now();
    // Late in the month, and still to come, whichever day the test runs.
    final start = DateTime(now.year, now.month, now.day).add(
      const Duration(hours: 30),
    );
    final thisMonth = start.month == now.month
        ? 'THIS MONTH'
        : DateFormat.yMMMM().format(start).toUpperCase();

    await tester.pumpWidget(_app(upcoming: [_ticket('1', 'Sky Hall', start)]));
    await tester.pumpAndSettle();

    expect(find.text(thisMonth), findsOneWidget);
    expect(
      find.text(DateFormat.MMM().format(start).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('${start.day}'), findsOneWidget);
    expect(find.text('Sky Hall'), findsOneWidget);
  });

  testWidgets(
      'upcoming bookings in later months get a header each, with the '
      'year', (tester) async {
    phone(tester);
    final now = DateTime.now();
    final later = DateTime(now.year + 1, 3, 12, 18);
    final latest = DateTime(now.year + 1, 5, 2, 18);

    await tester.pumpWidget(
      _app(
        upcoming: [
          _ticket('1', 'March party', later),
          _ticket('2', 'May gala', latest),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormat.yMMMM().format(later).toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(DateFormat.yMMMM().format(latest).toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('the same month of two years is two groups', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      _app(
        past: [
          _ticket('1', 'Last year', DateTime(2025, 11, 5, 18)),
          _ticket('2', 'Year before', DateTime(2024, 11, 5, 18)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('NOVEMBER 2025'), findsOneWidget);
    expect(find.text('NOVEMBER 2024'), findsOneWidget);
  });

  testWidgets('the date block does not squeeze the ticket on a narrow phone', (
    tester,
  ) async {
    phone(tester, width: 320);
    final start = DateTime.now().add(const Duration(days: 3));

    await tester.pumpWidget(_app(upcoming: [_ticket('1', 'Sky Hall', start)]));
    await tester.pumpAndSettle();

    expect(find.text('FXP-1'), findsOneWidget);
    expect(find.text('${start.day}'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
