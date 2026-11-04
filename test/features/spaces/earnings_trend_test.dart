import 'package:flutter_template/features/spaces/domain/earnings_trend.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_test/flutter_test.dart';

PayoutRow _row(DateTime on, num amount, {String status = 'paid'}) => PayoutRow(
      id: '${on.microsecondsSinceEpoch}$amount',
      amount: amount,
      status: status,
      source: 'event_venue_transaction',
      paidAt: on,
    );

void main() {
  final now = DateTime(2026, 11, 15, 10);

  group('weeklyPaid', () {
    test('puts each payout in the week it was paid, latest last', () {
      final weeks = weeklyPaid(
        [
          _row(DateTime(2026, 11, 14), 100), // 1 day ago: this week
          _row(DateTime(2026, 11, 9), 50), // 6 days ago: this week
          _row(DateTime(2026, 11, 8), 70), // 7 days ago: last week
          _row(DateTime(2026, 9, 21), 30), // 55 days ago: first week
        ],
        now,
      );

      expect(weeks, hasLength(8));
      expect(weeks.last, 150);
      expect(weeks[6], 70);
      expect(weeks.first, 30);
    });

    test('ignores pending, failed and older payouts', () {
      final weeks = weeklyPaid(
        [
          _row(DateTime(2026, 11, 14), 100, status: 'pending'),
          _row(DateTime(2026, 11, 14), 100, status: 'failed'),
          _row(DateTime(2026, 8), 100),
        ],
        now,
      );

      expect(weeks.every((w) => w == 0), isTrue);
    });
  });

  group('monthChange', () {
    test('is the percentage against last month', () {
      final change = monthChange(
        [
          _row(DateTime(2026, 11, 3), 150),
          _row(DateTime(2026, 10, 20), 100),
        ],
        now,
      );

      expect(change, 50);
    });

    test('can be a fall', () {
      final change = monthChange(
        [
          _row(DateTime(2026, 11, 3), 50),
          _row(DateTime(2026, 10, 20), 100),
        ],
        now,
      );

      expect(change, -50);
    });

    test('is null when nothing was paid last month', () {
      expect(monthChange([_row(DateTime(2026, 11, 3), 50)], now), isNull);
    });

    test('looks back across the new year', () {
      final change = monthChange(
        [
          _row(DateTime(2027, 1, 5), 200),
          _row(DateTime(2026, 12, 5), 100),
        ],
        DateTime(2027, 1, 20),
      );

      expect(change, 100);
    });
  });
}
