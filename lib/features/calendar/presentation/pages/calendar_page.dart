import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/widgets/venue_hold_chip.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Calendar: everything the person booked, hosts, organizes or supplies, in
/// one month grid with a list for the chosen day. One calendar for every role;
/// what is on it is scoped by the API.
///
/// It is the Calendar switch of the Bookings screen, so it draws no title or
/// back button of its own: just the month and what is on it.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({
    required this.onOpenTickets,
    this.manageVenues = false,
    this.initialVenueId,
    super.key,
  });

  /// "Open tickets" on a booking the person holds: show the Bookings list.
  final VoidCallback onOpenTickets;

  /// In the Venue space: also draws the days the person closed on their
  /// venues, says where each booking stands, lets them filter by venue, and
  /// lets them open or close a day.
  final bool manageVenues;

  /// With [manageVenues]: show this venue on its own to begin with, as when
  /// arriving from a venue's page.
  final String? initialVenueId;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late DateTime _month = _firstOfMonth(DateTime.now());
  late DateTime _selected = _dayOf(DateTime.now());
  final Set<CalendarRole> _hidden = {};

  /// The one venue to show, or null for all of them.
  late String? _venueFilter = widget.initialVenueId;

  @override
  void didUpdateWidget(CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab is kept alive, so a later arrival from another venue's page
    // reaches this same state: follow it.
    if (widget.initialVenueId != oldWidget.initialVenueId) {
      _venueFilter = widget.initialVenueId;
    }
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  /// The first cell of the grid: the start of the week holding the 1st.
  DateTime _gridStart(int firstWeekday) {
    // DateTime.weekday: Monday 1 … Sunday 7. firstWeekday uses the same.
    final lead = (_month.weekday - firstWeekday + 7) % 7;
    return _month.subtract(Duration(days: lead));
  }

  final GlobalKey _agendaKey = GlobalKey();

  /// Picks a day. In the Venue space the list for that day may sit below a
  /// full month, so it is brought into view.
  void _select(DateTime day) {
    setState(() => _selected = day);
    if (!widget.manageVenues) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _agendaKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        // The heading lands a little below the middle, so the lower weeks of
        // the grid stay in sight above the list.
        alignment: 0.45,
      );
    });
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
    final entries = ref.watch(
      widget.manageVenues
          ? venueCalendarProvider(range)
          : calendarEntriesProvider(range),
    );
    final venues = widget.manageVenues
        ? ref.watch(myVenuesProvider).asData?.value ?? const <SpaceListing>[]
        : const <SpaceListing>[];

    // Pull to refresh (from #116) now wraps the embedded calendar.
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () => _refresh(range),
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
          onToday: _today,
          onSelect: _select,
          agendaKey: _agendaKey,
          onToggleRole: _toggleRole,
          onOpenTickets: widget.onOpenTickets,
          manageVenues: widget.manageVenues,
          venues: venues,
          venueFilter: _venueFilter,
          onVenueFilter: (id) => setState(() => _venueFilter = id),
          onManageDay: () => unawaited(_manageDay(range, venues)),
          onOpenDay: (entry) => unawaited(_openDay(range, entry)),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref
            ..invalidate(calendarEntriesProvider)
            ..invalidate(venueCalendarProvider),
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
          onToday: _today,
          onSelect: _select,
          agendaKey: _agendaKey,
          onToggleRole: _toggleRole,
          onOpenTickets: widget.onOpenTickets,
          manageVenues: widget.manageVenues,
          venues: venues,
          venueFilter: _venueFilter,
          onVenueFilter: (id) => setState(() => _venueFilter = id),
          onManageDay: () => unawaited(_manageDay(range, venues)),
          onOpenDay: (entry) => unawaited(_openDay(range, entry)),
        ),
      ),
    );
  }

  /// Pull to refresh holds the spinner until the new entries have arrived.
  Future<void> _refresh(CalendarRange range) async {
    final provider = widget.manageVenues
        ? venueCalendarProvider(range)
        : calendarEntriesProvider(range);
    ref.invalidate(provider);
    try {
      await ref.read(provider.future);
    } on Object {
      // The page shows its own error state with a retry.
    }
  }

  /// Opens the sheet that opens or closes the chosen day on each venue.
  Future<void> _manageDay(CalendarRange range, List<SpaceListing> venues) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) =>
          _DayManageSheet(range: range, day: _selected, venues: venues),
    );
  }

  /// Opens a closed day again, from its entry in the list.
  Future<void> _openDay(CalendarRange range, CalendarEntry block) async {
    final venueId = block.venueId;
    if (venueId == null) return;
    final failed = context.l10n.calendarDayFailed;
    try {
      await ref.read(spacesRepositoryProvider).unblockDay(venueId, block.start);
      ref.invalidate(venueCalendarProvider(range));
    } on Object {
      if (mounted) showTopToast(context, failed);
    }
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
    required this.onToday,
    required this.onOpenTickets,
    this.manageVenues = false,
    this.venues = const [],
    this.venueFilter,
    this.onVenueFilter,
    this.agendaKey,
    this.onManageDay,
    this.onOpenDay,
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
  final VoidCallback onToday;
  final VoidCallback onOpenTickets;

  /// The Venue space's calendar: see [CalendarView.manageVenues].
  final bool manageVenues;
  final List<SpaceListing> venues;
  final String? venueFilter;
  final ValueChanged<String?>? onVenueFilter;
  final VoidCallback? onManageDay;

  /// Marks the heading of the chosen day's list, to scroll it into view.
  final Key? agendaKey;
  final ValueChanged<CalendarEntry>? onOpenDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final visible = [
      for (final e in entries)
        if (!hidden.contains(e.role) &&
            // With one venue chosen, other venues' bookings and closed days go;
            // anything that is not at a venue stays.
            (venueFilter == null ||
                e.venueId == null ||
                e.venueId == venueFilter))
          e,
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // With many venues a row of chips for each would fill the screen, so
        // the choice is one button that opens a list with a search.
        if (manageVenues && venues.length > 1) ...[
          _VenueSelector(
            venues: venues,
            selectedId: venueFilter,
            onChanged: (id) => onVenueFilter?.call(id),
          ),
          const SizedBox(height: 8),
        ],
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
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(l10n.calendarToday),
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
                        if (!e.isBlock &&
                            e.coversDay(
                              gridStart.add(Duration(days: week * 7 + d)),
                            ))
                          e.role,
                    },
                    blocked: visible.any(
                      (e) =>
                          e.isBlock &&
                          e.coversDay(
                            gridStart.add(Duration(days: week * 7 + d)),
                          ),
                    ),
                    awaitingReply: visible.any(
                      (e) =>
                          e.hold == VenueHold.awaitingReply &&
                          e.coversDay(
                            gridStart.add(Duration(days: week * 7 + d)),
                          ),
                    ),
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
          const SizedBox(height: 12),
          // One scrolling row, so the legend never grows into a block that
          // pushes the day's list off the screen.
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final role in present)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: !hidden.contains(role),
                      onSelected: (_) => onToggleRole(role),
                      avatar: CircleAvatar(
                        radius: 5,
                        backgroundColor: roleColor(role),
                      ),
                      label: Text(roleLabel(l10n, role)),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          key: agendaKey,
          children: [
            Expanded(
              child: Text(
                DateFormat.MMMEd(locale).format(selected).toUpperCase(),
                style: AppTypography.label(),
              ),
            ),
            if (manageVenues && venues.isNotEmpty)
              TextButton.icon(
                onPressed: onManageDay,
                icon: const Icon(Icons.event_busy_outlined, size: 18),
                label: Text(l10n.calendarDayManage),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size(0, 40),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (dayEntries.isEmpty && !loading)
          Text(
            l10n.calendarNothingToday,
            style: AppTypography.body(color: AppColors.textMuted),
          )
        else
          for (final entry in dayEntries) ...[
            _EntryTile(
              entry: entry,
              locale: locale,
              onOpenTickets: onOpenTickets,
              onOpenDay: manageVenues ? onOpenDay : null,
            ),
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
    this.blocked = false,
    this.awaitingReply = false,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final Set<CalendarRole> roles;
  final VoidCallback onTap;

  /// The venue's owner closed this day.
  final bool blocked;

  /// A booking at their venue is waiting for their reply.
  final bool awaitingReply;

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
            color: isSelected
                ? AppColors.accentTintBg
                : blocked
                    ? AppColors.surfaceRaised
                    : Colors.transparent,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : awaitingReply
                      ? AppColors.warning
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
                    // A closed day: a small lock, not a booking's dot.
                    if (blocked)
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 8,
                        color: AppColors.textMuted,
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
  const _EntryTile({
    required this.entry,
    required this.locale,
    required this.onOpenTickets,
    this.onOpenDay,
  });

  final CalendarEntry entry;
  final String locale;
  final VoidCallback onOpenTickets;

  /// On a closed day, in the Venue space: open it again.
  final ValueChanged<CalendarEntry>? onOpenDay;

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
    final color = entry.isBlock ? AppColors.textMuted : roleColor(entry.role);
    final hold = entry.hold;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        // A closed day has nothing to open; its action is on the tile.
        onTap: entry.isBlock ? null : () => _open(context),
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
                          entry.isBlock
                              ? l10n.calendarBlocked
                              : '${_when()} · ${roleLabel(l10n, entry.role)}',
                          style: AppTypography.body(
                            size: 12,
                          ),
                        ),
                        if (hold != null) ...[
                          const SizedBox(height: 6),
                          VenueHoldChip(hold: hold),
                        ],
                        if (entry.isBlock && onOpenDay != null)
                          TextButton(
                            onPressed: () => onOpenDay!(entry),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              minimumSize: const Size(0, 40),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(l10n.calendarOpenDay),
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
                if (entry.hold != null) ...[
                  const SizedBox(height: 8),
                  VenueHoldChip(hold: entry.hold!),
                ] else if (entry.status.isNotEmpty) ...[
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
                      onOpenTickets();
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

/// Opens or closes one day on each of the person's venues. A day a venue is
/// booked cannot be closed; it can be opened again when it is closed.
class _DayManageSheet extends ConsumerWidget {
  const _DayManageSheet({
    required this.range,
    required this.day,
    required this.venues,
  });

  final CalendarRange range;
  final DateTime day;
  final List<SpaceListing> venues;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    SpaceListing venue, {
    required bool close,
  }) async {
    final failed = context.l10n.calendarDayFailed;
    try {
      final repo = ref.read(spacesRepositoryProvider);
      if (close) {
        await repo.blockDay(venue.id, day);
      } else {
        await repo.unblockDay(venue.id, day);
      }
      ref.invalidate(venueCalendarProvider(range));
    } on Object {
      if (context.mounted) showTopToast(context, failed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final entries =
        ref.watch(venueCalendarProvider(range)).asData?.value ?? const [];

    bool closed(SpaceListing v) => entries.any(
          (e) => e.isBlock && e.venueId == v.id && e.coversDay(day),
        );
    bool booked(SpaceListing v) => entries.any(
          (e) =>
              !e.isBlock &&
              e.role == CalendarRole.venue &&
              e.hold != null &&
              e.venueId == v.id &&
              e.coversDay(day),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calendarDayManageTitle(DateFormat.MMMEd(locale).format(day)),
            style: AppTypography.display(size: 18),
          ),
          const SizedBox(height: 12),
          for (final venue in venues)
            Builder(
              builder: (context) {
                final isClosed = closed(venue);
                final isBooked = booked(venue);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.display(size: 15),
                            ),
                            Text(
                              isBooked && !isClosed
                                  ? l10n.calendarDayBooked
                                  : isClosed
                                      ? l10n.calendarDayClosed
                                      : l10n.calendarDayOpen,
                              style: AppTypography.body(size: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        // On means open to bookings.
                        value: !isClosed,
                        activeThumbColor: AppColors.onAccent,
                        activeTrackColor: AppColors.accent,
                        onChanged: isBooked && !isClosed
                            ? null
                            : (open) => unawaited(
                                  _set(context, ref, venue, close: !open),
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// One button that says which venue the calendar shows, and opens a searchable
/// list to change it. A venue is cleared with the cross.
class _VenueSelector extends StatelessWidget {
  const _VenueSelector({
    required this.venues,
    required this.selectedId,
    required this.onChanged,
  });

  final List<SpaceListing> venues;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  Future<void> _open(BuildContext context) async {
    final pick = await showModalBottomSheet<_VenuePick>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _VenueSheet(venues: venues, selectedId: selectedId),
    );
    // Dismissing the sheet changes nothing; choosing All venues is a pick.
    if (pick != null) onChanged(pick.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chosen = venues.where((v) => v.id == selectedId).firstOrNull;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: () => unawaited(_open(context)),
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(
              color: chosen == null ? AppColors.border : AppColors.accent,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chosen?.name ?? l10n.calendarAllVenuesCount(venues.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(),
                ),
              ),
              if (chosen != null)
                IconButton(
                  tooltip: l10n.calendarShowAllVenues,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => onChanged(null),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A choice from the venue list: a venue, or all of them when [id] is null.
class _VenuePick {
  const _VenuePick(this.id);

  final String? id;
}

class _VenueSheet extends StatefulWidget {
  const _VenueSheet({required this.venues, required this.selectedId});

  final List<SpaceListing> venues;
  final String? selectedId;

  @override
  State<_VenueSheet> createState() => _VenueSheetState();
}

class _VenueSheetState extends State<_VenueSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = [
      for (final v in widget.venues)
        if (v.matches(_query)) v,
    ];
    final searching = _query.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l10n.venuesSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  // All venues is offered unless a search is narrowing things.
                  if (!searching)
                    ListTile(
                      leading: const Icon(Icons.layers_outlined),
                      title: Text(
                        l10n.calendarAllVenuesCount(widget.venues.length),
                      ),
                      trailing: widget.selectedId == null
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () =>
                          Navigator.of(context).pop(const _VenuePick(null)),
                    ),
                  for (final v in shown)
                    ListTile(
                      title: Text(v.name, maxLines: 1),
                      subtitle: v.city == null ? null : Text(v.city!),
                      trailing: v.id == widget.selectedId
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(_VenuePick(v.id)),
                    ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.venuesNoMatch,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
