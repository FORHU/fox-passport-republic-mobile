import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEntry _entry(
  String id,
  CalendarRole role,
  String title, {
  int startHour = 19,
  int endHour = 23,
}) {
  final now = DateTime.now();
  return CalendarEntry(
    id: id,
    role: role,
    title: title,
    start: DateTime(now.year, now.month, now.day, startHour),
    end: DateTime(now.year, now.month, now.day, endHour),
    status: 'confirmed',
  );
}

Widget _app(Future<List<CalendarEntry>> Function() load) {
  return ProviderScope(
    // Riverpod retries a failed provider by itself; the error test wants the
    // error state, then a tap.
    retry: (_, __) => null,
    overrides: [
      calendarEntriesProvider.overrideWith((ref, range) => load()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CalendarPage(),
    ),
  );
}

void main() {
  group('CalendarEntry', () {
    test('reads a row and ignores one it cannot place', () {
      final entry = CalendarEntry.tryParse({
        'id': 'booking:b1',
        'kind': 'event',
        'role': 'guest',
        'title': 'Garden Party',
        'start': '2026-12-20T10:00:00.000Z',
        'end': '2026-12-20T14:00:00.000Z',
        'status': 'confirmed',
      })!;
      expect(entry.role, CalendarRole.guest);
      expect(entry.title, 'Garden Party');
      expect(entry.end.isAfter(entry.start), isTrue);

      expect(CalendarEntry.tryParse({'role': 'nobody', 'start': 'x'}), isNull);
      expect(
        CalendarEntry.tryParse({
          'role': 'host',
          'start': 'not a date',
        }),
        isNull,
      );
    });

    test('an entry covers each day it touches, not the one after midnight', () {
      final entry = CalendarEntry(
        id: 'e',
        role: CalendarRole.host,
        title: 'Two nights',
        start: DateTime(2026, 12, 20, 20),
        end: DateTime(2026, 12, 22),
        status: '',
      );
      expect(entry.coversDay(DateTime(2026, 12, 19)), isFalse);
      expect(entry.coversDay(DateTime(2026, 12, 20)), isTrue);
      expect(entry.coversDay(DateTime(2026, 12, 21)), isTrue);
      expect(entry.coversDay(DateTime(2026, 12, 22)), isFalse);
    });
  });

  group('CalendarPage', () {
    testWidgets('lists what is on the chosen day and filters by role', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          () async => [
            _entry('a', CalendarRole.guest, 'Rooftop Launch Night'),
            _entry('b', CalendarRole.host, 'Garden Birthday', startHour: 10),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rooftop Launch Night'), findsOneWidget);
      expect(find.text('Garden Birthday'), findsOneWidget);

      await tester.tap(find.text('Events I host'));
      await tester.pumpAndSettle();

      expect(find.text('Garden Birthday'), findsNothing);
      expect(find.text('Rooftop Launch Night'), findsOneWidget);
    });

    testWidgets('says so when the day is empty', (tester) async {
      await tester.pumpWidget(_app(() async => <CalendarEntry>[]));
      await tester.pumpAndSettle();

      expect(find.text('Nothing on this day.'), findsOneWidget);
    });

    testWidgets('a failed load says so and can be retried', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _app(() async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return [_entry('a', CalendarRole.guest, 'Rooftop Launch Night')];
        }),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Rooftop Launch Night'), findsOneWidget);
    });
  });
}
