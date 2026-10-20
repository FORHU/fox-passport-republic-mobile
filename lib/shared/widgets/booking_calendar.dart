import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// A one-month calendar, Monday first. Unavailable and past days are struck
/// out and cannot be chosen; the chosen day is a lime circle.
class BookingCalendar extends StatelessWidget {
  const BookingCalendar({
    required this.month,
    required this.today,
    required this.selected,
    required this.unavailable,
    required this.onSelect,
    required this.onMonthChanged,
    this.selectedEnd,
    this.monthsAhead = 11,
    super.key,
  });

  /// Any day in the month shown.
  final DateTime month;
  final DateTime today;
  final DateTime? selected;

  /// The last day of a chosen range; the days from [selected] to here are
  /// tinted. Null for a single day.
  final DateTime? selectedEnd;
  final Set<DateTime> unavailable;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  /// How many months past the current one can be browsed.
  final int monthsAhead;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final first = DateTime(month.year, month.month);
    final thisMonth = DateTime(today.year, today.month);
    final lastMonth = DateTime(today.year, today.month + monthsAhead);
    final canGoBack = first.isAfter(thisMonth);
    final canGoForward = first.isBefore(lastMonth);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1; // Monday = 0
    final cells = ((leading + daysInMonth + 6) ~/ 7) * 7;
    final taken = {for (final d in unavailable) _day(d)};

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MonthArrow(
              icon: Icons.chevron_left_rounded,
              tooltip: context.l10n.calendarPreviousMonth,
              enabled: canGoBack,
              onTap: () =>
                  onMonthChanged(DateTime(first.year, first.month - 1)),
            ),
            Text(
              DateFormat.yMMMM(locale).format(first),
              style: AppTypography.display(size: 14),
            ),
            _MonthArrow(
              icon: Icons.chevron_right_rounded,
              tooltip: context.l10n.calendarNextMonth,
              enabled: canGoForward,
              onTap: () =>
                  onMonthChanged(DateTime(first.year, first.month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat.E(locale)
                        .format(DateTime(2024, 1, 1 + i))
                        .substring(0, 1)
                        .toUpperCase(),
                    style: AppTypography.label(color: AppColors.textFaint),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < cells ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _cell(
                    row * 7 + col - leading + 1,
                    daysInMonth,
                    taken,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(l10n.bookSelected, style: AppTypography.body(size: 12)),
            const SizedBox(width: 16),
            Text(
              l10n.bookBooked,
              style: AppTypography.body(size: 12).copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell(int dayOfMonth, int daysInMonth, Set<DateTime> taken) {
    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
      return const SizedBox(height: 44);
    }
    final date = DateTime(month.year, month.month, dayOfMonth);
    final isPast = date.isBefore(_day(today));
    final isTaken = taken.contains(date);
    final enabled = !isPast && !isTaken;
    final start = selected == null ? null : _day(selected!);
    final end = selectedEnd == null ? null : _day(selectedEnd!);
    final isSelected = date == start || date == end;
    final inRange = start != null &&
        end != null &&
        date.isAfter(start) &&
        date.isBefore(end);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected,
      label: DateFormat.yMMMMd().format(date),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onSelect(date) : null,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.accent
                    : inRange
                        ? AppColors.accent.withValues(alpha: 0.25)
                        : Colors.transparent,
              ),
              child: Text(
                '$dayOfMonth',
                style: AppTypography.display(
                  size: 14,
                  color: isSelected
                      ? AppColors.onAccent
                      : enabled
                          ? AppColors.textPrimary
                          : AppColors.textFaint,
                ).copyWith(
                  decoration: enabled ? null : TextDecoration.lineThrough,
                  decorationColor: AppColors.textFaint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(
        icon,
        size: 22,
        color: enabled ? AppColors.textPrimary : AppColors.textFaint,
      ),
    );
  }
}
