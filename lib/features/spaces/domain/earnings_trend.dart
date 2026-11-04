import 'package:flutter_template/features/spaces/domain/space_models.dart';

/// When a payout counts: the day it was paid, else the day it was created.
DateTime? _paidOn(PayoutRow row) => row.paidAt ?? row.createdAt;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Money paid out in each of the last [weeks] weeks, oldest first, ending
/// with the week that includes [now]. A week is the seven days counted back
/// from today. Pending and failed payouts are not counted.
List<num> weeklyPaid(List<PayoutRow> rows, DateTime now, {int weeks = 8}) {
  final today = _day(now);
  final totals = List<num>.filled(weeks, 0);
  for (final row in rows) {
    if (row.status != 'paid') continue;
    final on = _paidOn(row);
    if (on == null) continue;
    final ago = today.difference(_day(on)).inDays;
    if (ago < 0 || ago >= weeks * 7) continue;
    totals[weeks - 1 - ago ~/ 7] += row.amount;
  }
  return totals;
}

/// How much more or less was paid this calendar month than last, as a
/// percentage; null when nothing was paid last month, since a change from
/// nothing has no percentage.
double? monthChange(List<PayoutRow> rows, DateTime now) {
  num sum(int year, int month) {
    num total = 0;
    for (final row in rows) {
      if (row.status != 'paid') continue;
      final on = _paidOn(row);
      if (on != null && on.year == year && on.month == month) {
        total += row.amount;
      }
    }
    return total;
  }

  final last = DateTime(now.year, now.month - 1);
  final before = sum(last.year, last.month);
  if (before <= 0) return null;
  return (sum(now.year, now.month) - before) / before * 100;
}
