import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _entry(String title) {
  final now = DateTime.now();
  return CalendarEntry(
    id: 'a',
    role: CalendarRole.guest,
    title: title,
    start: DateTime(now.year, now.month, now.day, 19),
    end: DateTime(now.year, now.month, now.day, 23),
    status: 'confirmed',
  );
}

Widget _app({String? segment, List<CalendarEntry> entries = const []}) {
  return ProviderScope(
    retry: (_, __) => null,
    overrides: [
      availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
      upcomingTicketsProvider.overrideWith((ref) async => [Ticket.sample()]),
      pastTicketsProvider.overrideWith((ref) async => <Ticket>[]),
      myMatchRequestsProvider.overrideWith(
        (ref) async => <MatchRequestItem>[],
      ),
      calendarEntriesProvider.overrideWith((ref, range) async => entries),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TicketsPage(initialSegment: segment),
    ),
  );
}

void _screen(WidgetTester tester, {double width = 800}) {
  tester.view
    ..physicalSize = Size(width, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Bookings switches between Upcoming, Requests, Past, Calendar', (
    tester,
  ) async {
    _screen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // The tabs are states only. The calendar is the second half of the
    // List | Calendar toggle in the header, not a tab.
    for (final label in ['Upcoming', 'Requests', 'Past']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Calendar'), findsNothing);
    expect(find.bySemanticsLabel('List view'), findsOneWidget);
    expect(find.bySemanticsLabel('Calendar view'), findsOneWidget);
  });

  testWidgets('the calendar view shows the month, under the same title', (
    tester,
  ) async {
    _screen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Calendar view'));
    await tester.pumpAndSettle();

    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing on this day.'), findsOneWidget);
    // The state tabs belong to the list; the toggle is the way back.
    expect(find.text('Requests'), findsNothing);
    expect(find.bySemanticsLabel('List view'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('List view'));
    await tester.pumpAndSettle();
    expect(find.text('Sky Hall'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('a link can open Bookings on the Calendar', (tester) async {
    _screen(tester);
    await tester.pumpWidget(_app(segment: 'calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(RouteNames.ticketsCalendar, '/tickets?segment=calendar');
  });

  testWidgets('Open tickets on a calendar booking returns to the list', (
    tester,
  ) async {
    _screen(tester);
    await tester.pumpWidget(
      _app(segment: 'calendar', entries: [_entry('Rooftop Launch Night')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rooftop Launch Night'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open tickets'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsNothing);
    expect(find.text('Sky Hall'), findsOneWidget);
  });

  testWidgets('the tabs and the toggle lay out on a small phone', (
    tester,
  ) async {
    _screen(tester, width: 320);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Whether each word fits whole depends on the real font, which widget
    // tests do not load; that needs a look on a device.
    expect(tester.takeException(), isNull);
    for (final label in ['Upcoming', 'Requests', 'Past']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.bySemanticsLabel('Calendar view'), findsOneWidget);
  });

  testWidgets('the chosen tab is kept when going to the calendar and back', (
    tester,
  ) async {
    _screen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Calendar view'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('List view'));
    await tester.pumpAndSettle();

    // Still on Past (the sample upcoming booking is not listed).
    expect(find.text('Sky Hall'), findsNothing);
    expect(find.text('Requests'), findsOneWidget);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('the header toggle fits 320 px, text x$scale', (tester) async {
      _screen(tester, width: 320);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Calendar view'), findsOneWidget);
    });
  }

  test('the tab bar has five tabs, and Calendar is not one of them', () {
    expect(RouteNames.shellTabs, hasLength(5));
    expect(RouteNames.shellTabs, isNot(contains('/calendar')));
  });
}
