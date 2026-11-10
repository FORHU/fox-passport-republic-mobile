import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/match_request_card.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/offline_note.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/tickets_skeleton.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// What the list shows. The calendar is a different way to look at bookings,
/// not another state, so it is a view switch in the header (see [_ViewToggle]).
enum _Segment { upcoming, requests, past }

/// Tickets: the bookings the user holds, upcoming and past.
class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({this.initialSegment, super.key});

  /// `requests` opens on the Match requests switch, `calendar` on the
  /// calendar view.
  final String? initialSegment;

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  late _Segment _segment = _fromParam(widget.initialSegment);
  late bool _calendar = widget.initialSegment == 'calendar';

  static _Segment _fromParam(String? value) => switch (value) {
        'requests' => _Segment.requests,
        _ => _Segment.upcoming,
      };

  @override
  void didUpdateWidget(TicketsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shell keeps this page alive, so a link arrives as an update.
    if (oldWidget.initialSegment != widget.initialSegment &&
        widget.initialSegment != null) {
      setState(() {
        _segment = _fromParam(widget.initialSegment);
        _calendar = widget.initialSegment == 'calendar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tickets = _segment == _Segment.upcoming
        ? ref.watch(upcomingTicketsProvider)
        : ref.watch(pastTicketsProvider);
    final requests = ref.watch(myMatchRequestsProvider);

    final header = Row(
      children: [
        if (Navigator.canPop(context))
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        Expanded(
          child: Text(
            l10n.bookings,
            style: AppTypography.display(size: 28),
          ),
        ),
        _ViewToggle(
          calendar: _calendar,
          onChanged: (calendar) => setState(() => _calendar = calendar),
        ),
      ],
    );
    final pills = SegmentedPills<_Segment>(
      value: _segment,
      onChanged: (v) => setState(() => _segment = v),
      options: [
        SegmentOption(_Segment.upcoming, l10n.ticketsUpcoming),
        SegmentOption(_Segment.requests, l10n.ticketsRequests),
        SegmentOption(_Segment.past, l10n.ticketsPast),
      ],
    );

    // The calendar draws its own scrolling month, so it sits below a fixed
    // header instead of inside the list the other views share. It has its own
    // role filter, so the Upcoming / Requests / Past switch is not shown.
    if (_calendar) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: header,
              ),
              Expanded(
                child: CalendarView(
                  onOpenTickets: () => setState(() {
                    _calendar = false;
                    _segment = _Segment.upcoming;
                  }),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref
              ..invalidate(upcomingTicketsProvider)
              ..invalidate(pastTicketsProvider)
              ..invalidate(myMatchRequestsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              header,
              const SizedBox(height: 16),
              ..._needsYou(requests.asData?.value ?? const [], l10n),
              pills,
              const SizedBox(height: 16),
              if (_segment == _Segment.requests)
                ...requests.when(
                  loading: () => const [RequestsSkeleton()],
                  error: (_, __) => [
                    _loadError(
                      l10n.apiLoadFailed,
                      l10n.retry,
                      () => ref.invalidate(myMatchRequestsProvider),
                    ),
                  ],
                  data: (list) => list.every((r) => r.needsPayment)
                      ? [_empty(l10n.ticketsEmptyRequests)]
                      : [
                          // What needs the person is shown above, once.
                          for (final r in list.where((r) => !r.needsPayment))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: MatchRequestCard(item: r),
                            ),
                        ],
                )
              else
                ...tickets.when(
                  loading: () => const [TicketsSkeleton()],
                  error: (_, __) => [
                    _loadError(l10n.apiLoadFailed, l10n.retry, () {
                      if (_segment == _Segment.upcoming) {
                        ref.invalidate(upcomingTicketsProvider);
                      } else {
                        ref.invalidate(pastTicketsProvider);
                      }
                    }),
                  ],
                  data: (list) {
                    if (list.isEmpty) {
                      return [
                        _empty(
                          _segment == _Segment.upcoming
                              ? l10n.ticketsEmptyUpcoming
                              : l10n.ticketsEmptyPast,
                        ),
                      ];
                    }
                    if (_segment == _Segment.past) {
                      return _groupedByMonth(list);
                    }
                    final saved = list.map((t) => t.cachedAt).nonNulls;
                    return [
                      // Saved on the phone, not just fetched: say so.
                      if (saved.isNotEmpty)
                        OfflineTicketsNote(savedAt: saved.first),
                      for (final t in list) _item(t),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Anything waiting on the person, in a lime-bordered block on top.
  List<Widget> _needsYou(List<MatchRequestItem> all, AppLocalizations l10n) {
    final waiting = [
      for (final r in all)
        if (r.needsPayment) r,
    ];
    if (waiting.isEmpty) return const [];
    return [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingsNeedsYou.toUpperCase(),
              style: AppTypography.label(color: AppColors.accent),
            ),
            const SizedBox(height: 10),
            for (final r in waiting) ...[
              MatchRequestCard(item: r),
              if (r != waiting.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _item(Ticket ticket) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TicketCard(ticket: ticket),
      );

  /// Groups past tickets under month headers, newest month first.
  List<Widget> _groupedByMonth(List<Ticket> tickets) {
    final locale = Localizations.localeOf(context).toString();
    final grouped = <String, List<Ticket>>{};
    for (final t in tickets) {
      final key = DateFormat.MMMM(locale).format(t.startAt);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            entry.key.toUpperCase(),
            style: AppTypography.label(),
          ),
        ),
      );
      for (final t in entry.value) {
        widgets.add(_item(t));
      }
    }
    return widgets;
  }

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ),
      );

  Widget _loadError(String message, String retry, VoidCallback onRetry) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              TextButton(onPressed: onRetry, child: Text(retry)),
            ],
          ),
        ),
      );
}

/// List | Calendar: two icons in a small pill, level with the title. The
/// chosen one is raised, as in [SegmentedPills]; each is a 44 px thumb target.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.calendar, required this.onChanged});

  final bool calendar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget option({
      required bool isCalendar,
      required IconData icon,
      required String label,
    }) {
      final selected = calendar == isCalendar;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(isCalendar),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.surfaceRaised : Colors.transparent,
                borderRadius: AppRadius.brPill,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(
            isCalendar: false,
            icon: Icons.view_agenda_outlined,
            label: l10n.ticketsViewList,
          ),
          option(
            isCalendar: true,
            icon: Icons.calendar_month_outlined,
            label: l10n.ticketsViewCalendar,
          ),
        ],
      ),
    );
  }
}
