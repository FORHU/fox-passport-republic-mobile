import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// A one-month calendar, Monday first. Unavailable and past days are struck
/// out and cannot be chosen; the chosen day is a lime circle. With
/// [rangeEnd], both ends are lime circles joined by a band over the days
/// between them.
class BookingCalendar extends StatelessWidget {
  const BookingCalendar({
    required this.month,
    required this.today,
    required this.selected,
    required this.unavailable,
    required this.onSelect,
    required this.onMonthChanged,
    this.rangeEnd,
    this.monthsAhead = 11,
    super.key,
  });

  /// Any day in the month shown.
  final DateTime month;
  final DateTime today;

  /// The chosen day, or the first day of a range.
  final DateTime? selected;

  /// The last day of a range, after [selected]; null for a single day.
  final DateTime? rangeEnd;
  final Set<DateTime> unavailable;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  /// How many months past the current one can be browsed.
  final int monthsAhead;

  /// The band behind the days a range covers.
  static final Color rangeBand = AppColors.accent.withValues(alpha: 0.24);

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
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 6),
            Text(l10n.bookSelected, style: AppTypography.body(size: 12)),
            if (rangeEnd != null) ...[
              const SizedBox(width: 16),
              Container(
                width: 18,
                height: 12,
                decoration: BoxDecoration(
                  color: rangeBand,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 6),
              Text(l10n.bookCovered, style: AppTypography.body(size: 12)),
            ],
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
    final end = rangeEnd == null ? null : _day(rangeEnd!);
    final isStart = start == date;
    final isEnd = end == date;
    final isSelected = isStart || isEnd;
    final isRange = start != null && end != null && end.isAfter(start);
    final isBetween = isRange && date.isAfter(start) && date.isBefore(end);
    // The band runs from the first day's centre to the last day's. It breaks
    // at the end of a week row and of the month: rounded there, and an end
    // day sitting at a break has no band on that side to join.
    final rowStart = date.weekday == DateTime.monday || dayOfMonth == 1;
    final rowEnd = date.weekday == DateTime.sunday || dayOfMonth == daysInMonth;
    final bandLeft = isRange && (isBetween || (isEnd && !rowStart));
    final bandRight = isRange && (isBetween || (isStart && !rowEnd));
    const round = Radius.circular(22);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: isSelected || isBetween,
      label: DateFormat.yMMMMd().format(date),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onSelect(date) : null,
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (bandLeft || bandRight)
                Positioned.fill(
                  top: 2,
                  bottom: 2,
                  // Stretch, or the childless halves collapse to no height.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          key: bandLeft ? const ValueKey('band') : null,
                          decoration: BoxDecoration(
                            color: bandLeft ? rangeBand : Colors.transparent,
                            borderRadius: isBetween && rowStart
                                ? const BorderRadius.horizontal(left: round)
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: DecoratedBox(
                          key: bandRight ? const ValueKey('band') : null,
                          decoration: BoxDecoration(
                            color: bandRight ? rangeBand : Colors.transparent,
                            borderRadius: isBetween && rowEnd
                                ? const BorderRadius.horizontal(right: round)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.accent : Colors.transparent,
                ),
                child: Text(
                  '$dayOfMonth',
                  style: AppTypography.display(
                    size: 14,
                    color: isSelected
                        ? AppColors.onAccent
                        : isBetween
                            ? AppColors.accent
                            : enabled
                                ? AppColors.textPrimary
                                : AppColors.textFaint,
                  ).copyWith(
                    decoration: enabled ? null : TextDecoration.lineThrough,
                    decorationColor: AppColors.textFaint,
                  ),
                ),
              ),
            ],
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
