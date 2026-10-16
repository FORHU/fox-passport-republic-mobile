import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Calendar: everything the person booked, hosts, organizes or supplies, in
/// one month grid with a list for the chosen day. One calendar for every role;
/// what is on it is scoped by the API.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month = _firstOfMonth(DateTime.now());
  late DateTime _selected = _dayOf(DateTime.now());
  final Set<CalendarRole> _hidden = {};

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  /// The first cell of the grid: the start of the week holding the 1st.
  DateTime _gridStart(int firstWeekday) {
    // DateTime.weekday: Monday 1 … Sunday 7. firstWeekday uses the same.
    final lead = (_month.weekday - firstWeekday + 7) % 7;
    return _month.subtract(Duration(days: lead));
  }

  void _go(int months) => setState(() {
        _month = DateTime(_month.year, _month.month + months);
        _selected = _month;
      });

  void _today() => setState(() {
        final now = DateTime.now();
        _month = _firstOfMonth(now);
        _selected = _dayOf(now);
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final material = MaterialLocalizations.of(context);
    // MaterialLocalizations counts Sunday as 0; DateTime counts Monday as 1.
    final firstWeekday =
        material.firstDayOfWeekIndex == 0 ? 7 : material.firstDayOfWeekIndex;
    final start = _gridStart(firstWeekday);
    final range = (from: start, to: start.add(const Duration(days: 42)));
    final entries = ref.watch(calendarEntriesProvider(range));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      tooltip: material.backButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.calendarTitle,
                      style: AppTypography.display(size: 28),
                    ),
                  ),
                  TextButton(
                    onPressed: _today,
                    child: Text(l10n.calendarToday),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.when(
                loading: () => _Body(
                  month: _month,
                  gridStart: start,
                  selected: _selected,
                  entries: const [],
                  hidden: _hidden,
                  loading: true,
                  locale: locale,
                  onMonth: _go,
                  onSelect: (d) => setState(() => _selected = d),
                  onToggleRole: _toggleRole,
                ),
                error: (_, __) => AppStateView(
                  kind: AppStateKind.error,
                  title: l10n.apiLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(calendarEntriesProvider),
                ),
                data: (list) => _Body(
                  month: _month,
                  gridStart: start,
                  selected: _selected,
                  entries: list,
                  hidden: _hidden,
                  loading: false,
                  locale: locale,
                  onMonth: _go,
                  onSelect: (d) => setState(() => _selected = d),
                  onToggleRole: _toggleRole,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRole(CalendarRole role) => setState(() {
        if (!_hidden.remove(role)) _hidden.add(role);
      });
}

/// Colour and name of each role, shared by the dots, the chips and the list.
Color roleColor(CalendarRole role) => switch (role) {
      CalendarRole.guest => AppColors.warning,
      CalendarRole.host => AppColors.accent,
      CalendarRole.organizer => AppColors.roleTalent,
      CalendarRole.venue => AppColors.roleVenue,
      CalendarRole.supplier => AppColors.roleGear,
    };

String roleLabel(AppLocalizations l10n, CalendarRole role) => switch (role) {
      CalendarRole.guest => l10n.calendarRoleGuest,
      CalendarRole.host => l10n.calendarRoleHost,
      CalendarRole.organizer => l10n.calendarRoleOrganizer,
      CalendarRole.venue => l10n.calendarRoleVenue,
      CalendarRole.supplier => l10n.calendarRoleSupplier,
    };

class _Body extends StatelessWidget {
  const _Body({
    required this.month,
    required this.gridStart,
    required this.selected,
    required this.entries,
    required this.hidden,
    required this.loading,
    required this.locale,
    required this.onMonth,
    required this.onSelect,
    required this.onToggleRole,
  });

  final DateTime month;
  final DateTime gridStart;
  final DateTime selected;
  final List<CalendarEntry> entries;
  final Set<CalendarRole> hidden;
  final bool loading;
  final String locale;
  final ValueChanged<int> onMonth;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<CalendarRole> onToggleRole;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final visible = [
      for (final e in entries)
        if (!hidden.contains(e.role)) e,
    ];
    final present = {for (final e in entries) e.role}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final dayEntries = [
      for (final e in visible)
        if (e.coversDay(selected)) e,
    ];
    final today = DateTime.now();
    final weekdayNames = [
      for (var i = 0; i < 7; i++)
        material.narrowWeekdays[(material.firstDayOfWeekIndex + i) % 7],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.calendarPreviousMonth,
              onPressed: () => onMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(month),
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 18),
              ),
            ),
            IconButton(
              tooltip: l10n.calendarNextMonth,
              onPressed: () => onMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final name in weekdayNames)
              Expanded(
                child: Center(
                  child: Text(name, style: AppTypography.label()),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: _DayCell(
                    day: gridStart.add(Duration(days: week * 7 + d)),
                    inMonth:
                        gridStart.add(Duration(days: week * 7 + d)).month ==
                            month.month,
                    isToday: _same(
                      gridStart.add(Duration(days: week * 7 + d)),
                      today,
                    ),
                    isSelected: _same(
                      gridStart.add(Duration(days: week * 7 + d)),
                      selected,
                    ),
                    roles: {
                      for (final e in visible)
                        if (e.coversDay(
                          gridStart.add(Duration(days: week * 7 + d)),
                        ))
                          e.role,
                    },
                    onTap: () =>
                        onSelect(gridStart.add(Duration(days: week * 7 + d))),
                  ),
                ),
            ],
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.border,
              minHeight: 2,
            ),
          ),
        if (present.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in present)
                FilterChip(
                  selected: !hidden.contains(role),
                  onSelected: (_) => onToggleRole(role),
                  avatar: CircleAvatar(
                    radius: 5,
                    backgroundColor: roleColor(role),
                  ),
                  label: Text(roleLabel(l10n, role)),
                  showCheckmark: false,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Text(
          DateFormat.MMMEd(locale).format(selected).toUpperCase(),
          style: AppTypography.label(),
        ),
        const SizedBox(height: 10),
        if (dayEntries.isEmpty && !loading)
          Text(
            l10n.calendarNothingToday,
            style: AppTypography.body(color: AppColors.textMuted),
          )
        else
          for (final entry in dayEntries) ...[
            _EntryTile(entry: entry, locale: locale),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.roles,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final Set<CalendarRole> roles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dots =
        (roles.toList()..sort((a, b) => a.index.compareTo(b.index))).take(3);
    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat.yMMMMEEEEd(
        Localizations.localeOf(context).toString(),
      ).format(day),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          height: 52,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentTintBg : Colors.transparent,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : isToday
                      ? AppColors.borderStrong
                      : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: AppTypography.body(
                  color: !inMonth
                      ? AppColors.textFaint
                      : isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                  weight: isToday ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final role in dots)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: roleColor(role),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.locale});

  final CalendarEntry entry;
  final String locale;

  String _when() {
    final time = DateFormat.jm(locale);
    final sameDay = entry.start.year == entry.end.year &&
        entry.start.month == entry.end.month &&
        entry.start.day == entry.end.day;
    if (entry.end == entry.start) return time.format(entry.start);
    return sameDay
        ? '${time.format(entry.start)} – ${time.format(entry.end)}'
        : '${DateFormat.MMMd(locale).format(entry.start)} – '
            '${DateFormat.MMMd(locale).format(entry.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = roleColor(entry.role);
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(size: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_when()} · ${roleLabel(l10n, entry.role)}',
                          style: AppTypography.body(
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final l10n = context.l10n;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleLabel(l10n, entry.role).toUpperCase(),
                  style: AppTypography.label(color: roleColor(entry.role)),
                ),
                const SizedBox(height: 6),
                Text(entry.title, style: AppTypography.display(size: 22)),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat.yMMMMEEEEd(locale).format(entry.start)}\n'
                  '${_when()}',
                  style: AppTypography.body(),
                ),
                if (entry.status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.status.replaceAll('_', ' ').toUpperCase(),
                    style: AppTypography.label(),
                  ),
                ],
                const SizedBox(height: 16),
                if (entry.role == CalendarRole.guest)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheet);
                      context.go(RouteNames.tickets);
                    },
                    child: Text(l10n.calendarOpenTickets),
                  )
                else
                  Text(
                    l10n.calendarManageOnWeb,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
