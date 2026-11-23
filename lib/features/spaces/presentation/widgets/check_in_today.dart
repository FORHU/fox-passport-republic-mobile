import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The first event, among [entries], that the person has in [role] and that
/// runs at some point today: it starts today, or started earlier and is still
/// on. Closed days and cancelled or declined bookings don't count.
CalendarEntry? eventToday(
  Iterable<CalendarEntry> entries,
  CalendarRole role, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final dayStart = DateTime(at.year, at.month, at.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  bool dropped(String status) {
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('reject') || s.contains('declin');
  }

  for (final e in entries) {
    if (e.role != role || e.isBlock || dropped(e.status)) continue;
    if (e.start.isBefore(dayEnd) && e.end.isAfter(dayStart)) return e;
  }
  return null;
}

/// On event day, a card at the top of the Dashboard with the event and a
/// button straight to Check-in, so it isn't only a row in More. Nothing on
/// other days.
class CheckInToday extends StatelessWidget {
  const CheckInToday({
    required this.entries,
    required this.role,
    required this.checkInRoute,
    this.now,
    super.key,
  });

  final Iterable<CalendarEntry> entries;
  final CalendarRole role;
  final String checkInRoute;

  /// For tests; the current time otherwise.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final entry = eventToday(entries, role, now: now);
    if (entry == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final at = now ?? DateTime.now();
    final started = !entry.start.isAfter(at);
    final when = started
        ? l10n.checkInTodayOn
        : l10n.checkInTodayAt(DateFormat.jm(locale).format(entry.start));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(size: 15),
            ),
            const SizedBox(height: 2),
            Text(
              when,
              style: AppTypography.body(size: 13, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('check-in-today'),
              onPressed: () => context.push(checkInRoute),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(l10n.checkInTodayButton),
            ),
          ],
        ),
      ),
    );
  }
}
