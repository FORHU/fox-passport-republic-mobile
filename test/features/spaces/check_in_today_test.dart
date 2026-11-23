import 'package:flutter/material.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/check_in_today.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _now = DateTime(2026, 11, 20, 15);

CalendarEntry _entry({
  required DateTime start,
  required DateTime end,
  CalendarRole role = CalendarRole.venue,
  String kind = 'event',
  String status = 'confirmed',
  String title = 'Garden Wedding',
}) =>
    CalendarEntry.tryParse({
      'id': 'e1',
      'role': role.name,
      'kind': kind,
      'title': title,
      'start': start.toUtc().toIso8601String(),
      'end': end.toUtc().toIso8601String(),
      'status': status,
    })!;

Future<void> _pump(WidgetTester tester, List<CalendarEntry> entries) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: CheckInToday(
            entries: entries,
            role: CalendarRole.venue,
            checkInRoute: '/check-in',
            now: _now,
          ),
        ),
      ),
      GoRoute(path: '/check-in', builder: (_, __) => const Text('check-in')),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('eventToday', () {
    test('finds an event that starts later today', () {
      final e = _entry(
        start: DateTime(2026, 11, 20, 18),
        end: DateTime(2026, 11, 21),
      );
      expect(eventToday([e], CalendarRole.venue, now: _now), e);
    });

    test('finds one that started yesterday and is still on', () {
      final e = _entry(
        start: DateTime(2026, 11, 19, 18),
        end: DateTime(2026, 11, 21, 23, 59),
      );
      expect(eventToday([e], CalendarRole.venue, now: _now), e);
    });

    test('skips other days, other roles, closed days and cancellations', () {
      final tomorrow = _entry(
        start: DateTime(2026, 11, 21, 18),
        end: DateTime(2026, 11, 22),
      );
      final asGuest = _entry(
        start: DateTime(2026, 11, 20, 18),
        end: DateTime(2026, 11, 21),
        role: CalendarRole.guest,
      );
      final closed = _entry(
        start: DateTime(2026, 11, 20),
        end: DateTime(2026, 11, 21),
        kind: 'block',
      );
      final cancelled = _entry(
        start: DateTime(2026, 11, 20, 18),
        end: DateTime(2026, 11, 21),
        status: 'cancelled',
      );
      expect(
        eventToday(
          [tomorrow, asGuest, closed, cancelled],
          CalendarRole.venue,
          now: _now,
        ),
        isNull,
      );
    });
  });

  testWidgets('on event day, the card opens Check-in', (tester) async {
    await _pump(tester, [
      _entry(start: DateTime(2026, 11, 20, 18), end: DateTime(2026, 11, 21)),
    ]);

    expect(find.text('Garden Wedding'), findsOneWidget);
    // intl puts a narrow no-break space before PM.
    expect(find.textContaining('Today at 6:00'), findsOneWidget);
    await tester.tap(find.text('Check in guests'));
    await tester.pumpAndSettle();
    expect(find.text('check-in'), findsOneWidget);
  });

  testWidgets('says On now once it has started', (tester) async {
    await _pump(tester, [
      _entry(
        start: DateTime(2026, 11, 20, 12),
        end: DateTime(2026, 11, 20, 20),
      ),
    ]);

    expect(find.text('On now'), findsOneWidget);
  });

  testWidgets('shows nothing on a day with no event', (tester) async {
    await _pump(tester, const []);

    expect(find.byKey(const ValueKey('check-in-today')), findsNothing);
  });
}
