import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('uses the currency it is given, not a fixed one', () {
      expect(formatMoney(25000, 'PHP'), '₱25,000');
      expect(formatMoney(25000, 'USD'), r'$25,000');
      expect(formatMoney(25000, 'EUR'), '€25,000');
    });

    test('keeps decimals only when there are some', () {
      expect(formatMoney(19.5, 'USD'), r'$19.50');
      expect(formatMoney(20, 'USD'), r'$20');
    });

    test('falls back to USD for an empty code', () {
      expect(formatMoney(5, ''), r'$5');
    });
  });

  group('Ticket', () {
    test('reads a booking from the API', () {
      final t = Ticket.fromBooking(const {
        'id': 'b1',
        'status': 'confirmed',
        'guestCount': 4,
        'startAt': '2026-10-17T19:00:00.000Z',
        'endAt': '2026-10-18T00:00:00.000Z',
        'ticketCode': 'FXP-1234',
        'event': {'name': 'Sky Hall', 'targetCity': 'Davao City'},
      });

      expect(t.id, 'b1');
      expect(t.eventName, 'Sky Hall');
      expect(t.city, 'Davao City');
      expect(t.guestCount, 4);
      expect(t.ticketCode, 'FXP-1234');
      expect(t.isSample, isFalse);
    });

    test('counts whole calendar days to the start', () {
      final t = Ticket.sample(DateTime(2026, 10, 14, 23, 30));
      expect(t.daysUntil(DateTime(2026, 10, 14, 23, 30)), 3);
      expect(t.isSample, isTrue);
    });
  });
}
