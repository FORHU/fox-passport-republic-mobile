import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Ticket _ticket(DateTime start, DateTime end) => Ticket(
      id: 't1',
      eventName: 'Social Night',
      startAt: start,
      endAt: end,
      status: 'confirmed',
    );

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('an evening that ends at midnight is one day', () {
    final t = _ticket(DateTime(2026, 11, 20, 18), DateTime(2026, 11, 21));
    expect(t.isMultiDay, isFalse);
    expect(t.dateLabel('en'), 'Fri 20 Nov');
  });

  test('a whole-day venue booking is one day', () {
    final t = _ticket(
      DateTime(2026, 11, 20),
      DateTime(2026, 11, 20, 23, 59, 59),
    );
    expect(t.isMultiDay, isFalse);
  });

  test('a booking over several days shows the range, short to fit', () {
    final package = _ticket(DateTime(2026, 11, 20, 18), DateTime(2026, 11, 23));
    expect(package.isMultiDay, isTrue);
    expect(package.lastDay, DateTime(2026, 11, 22));
    expect(package.dateLabel('en'), '20 – 22 Nov');

    final venue = _ticket(
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 2, 23, 59, 59),
    );
    expect(venue.dateLabel('en'), '30 Nov – 2 Dec');
  });
}
