import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:intl/intl.dart';

/// The days of [selection] as one line: "Fri 12 Dec", or
/// "Fri 12 Dec – Sun 14 Dec" for a venue booked for several days. [pattern]
/// is the `DateFormat` for each day.
///
/// Empty until a day is chosen.
String bookingDatesLabel(
  BookingSelection selection,
  String locale, {
  String pattern = 'EEE d MMM',
}) {
  final first = selection.date;
  if (first == null) return '';
  final format = DateFormat(pattern, locale);
  return selection.days == 1
      ? format.format(first)
      : '${format.format(first)} – ${format.format(selection.lastDate!)}';
}
