import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/booking_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _calendar({DateTime? rangeEnd}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BookingCalendar(
          month: DateTime(2026, 11),
          today: DateTime(2026, 11),
          selected: DateTime(2026, 11, 20),
          rangeEnd: rangeEnd,
          unavailable: const {},
          onSelect: (_) {},
          onMonthChanged: (_) {},
        ),
      ),
    );

/// The band pieces drawn behind one day.
Finder _bandOf(String day) => find.descendant(
      of: find.ancestor(of: find.text(day), matching: find.byType(Stack)),
      matching: find.byKey(const ValueKey('band')),
    );

void main() {
  testWidgets('a range covers every day between its ends', (tester) async {
    // Fri 20 to Mon 30 November 2026.
    await tester.pumpWidget(_calendar(rangeEnd: DateTime(2026, 11, 30)));

    expect(_bandOf('20'), findsOneWidget); // Right half only.
    expect(_bandOf('22'), findsNWidgets(2)); // Sunday: the row ends.
    expect(_bandOf('23'), findsNWidgets(2)); // Monday: a new row.
    // The 30th is a Monday: nothing on its row to join, so no stub.
    expect(_bandOf('30'), findsNothing);
    expect(find.text('Covered'), findsOneWidget);
  });

  testWidgets('a single day has no band and no Covered legend', (
    tester,
  ) async {
    await tester.pumpWidget(_calendar());

    expect(find.byKey(const ValueKey('band')), findsNothing);
    expect(find.text('Covered'), findsNothing);
  });
}
