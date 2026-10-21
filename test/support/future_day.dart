import 'package:flutter_test/flutter_test.dart';

/// Taps a day on a booking calendar that is ahead of today and is not one of
/// the sample venues' booked days (the 6th, 7th, 13th, 24th and 25th), so a
/// test does not depend on what today's date is.
///
/// A test that taps a fixed day fails as soon as the clock passes it: day 20
/// worked until the 20th, then "Next" never came on.
Future<void> tapFutureDay(WidgetTester tester) async {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  const sampleBooked = {6, 7, 13, 24, 25};

  int? day;
  for (var d = now.day + 1; d <= daysInMonth; d++) {
    if (!sampleBooked.contains(d)) {
      day = d;
      break;
    }
  }
  if (day == null) {
    // Nothing is left this month: next month's 20th is ahead and free.
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    day = 20;
  }
  await tester.tap(find.text('$day').first);
  await tester.pumpAndSettle();
}
