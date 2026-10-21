import 'package:flutter_test/flutter_test.dart';

const _sampleBooked = {6, 7, 13, 24, 25};

/// Taps a first day and a last day three days later on a booking calendar: both
/// ahead of today, with no sample booked day (the 6th, 7th, 13th, 24th, 25th)
/// in between. Whatever today is.
Future<void> tapFutureThreeDays(
  WidgetTester tester, {
  Future<void> Function()? afterFirst,
}) async {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  int? start;
  for (var d = now.day + 1; d + 2 <= daysInMonth; d++) {
    if (![d, d + 1, d + 2].any(_sampleBooked.contains)) {
      start = d;
      break;
    }
  }
  if (start == null) {
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    start = 20; // the 20th, 21st and 22nd are free
  }
  await tester.tap(find.text('$start').first);
  await tester.pumpAndSettle();
  await afterFirst?.call();
  await tester.tap(find.text('${start + 2}').first);
  await tester.pumpAndSettle();
}

/// Taps a first day, then a last day that is past a sample booked day, so the
/// range is refused: both ahead of today, and each free.
Future<void> tapRangeAcrossABookedDay(WidgetTester tester) async {
  final now = DateTime.now();
  // Free days either side of the booked 6th-7th, 13th, and 24th-25th.
  const options = [(4, 9), (11, 15), (22, 26)];

  (int, int)? chosen;
  for (final option in options) {
    if (option.$1 > now.day) {
      chosen = option;
      break;
    }
  }
  if (chosen == null) {
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    chosen = options.last;
  }
  await tester.tap(find.text('${chosen.$1}').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('${chosen.$2}').first);
  await tester.pumpAndSettle();
}
