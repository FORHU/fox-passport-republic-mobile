import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/widgets/venue_hold_chip.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The Venue space's first screen, in the order a Mayor needs it: the things
/// they do most, then what needs them (booking requests answered here, partner
/// applications, venues that are in review, declined or unfinished), then what
/// is on today and coming up, and last the numbers, each of which opens the
/// place where its detail lives.
class VenueOverviewPage extends ConsumerWidget {
  const VenueOverviewPage({super.key});

  /// The next 30 days, from the start of today. A stable key, so the calendar
  /// is fetched once however often this rebuilds.
  static CalendarRange _next30Days() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    return (from: from, to: from.add(const Duration(days: 30)));
  }

  Future<void> _refresh(WidgetRef ref, CalendarRange range) async {
    ref
      ..invalidate(venueRequestsProvider)
      ..invalidate(myVenuesProvider)
      ..invalidate(payoutsProvider)
      ..invalidate(partnersProvider)
      ..invalidate(venueCalendarProvider(range));
    try {
      await ref.read(venueRequestsProvider.future);
    } on Object {
      // Each part shows its own failure.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final range = _next30Days();

    final requests = ref.watch(venueRequestsProvider);
    final venues = ref.watch(myVenuesProvider);
    final payouts = ref.watch(payoutsProvider);
    final calendar = ref.watch(venueCalendarProvider(range));
    final partners = ref.watch(partnersProvider);
    final partnersWaiting =
        ref.watch(partnersWaitingProvider(PartnerSide.mayor));

    final waiting = [
      ...?requests.asData?.value.where((r) => r.needsReply),
    ];
    final myVenues = venues.asData?.value ?? const <SpaceListing>[];
    int inGroup(String group) => myVenues.where((v) => v.group == group).length;
    final inReview = inGroup('pending');
    final declined = inGroup('rejected');
    final drafts = inGroup('draft');

    final bookings = [
      ...?calendar.asData?.value.where(
        (e) => e.role == CalendarRole.venue && !e.isBlock && e.hold != null,
      ),
    ];
    // What is ahead and settled or held. Bookings still waiting for a reply are
    // already in the list above.
    final ahead = [
      for (final e in bookings)
        if (e.hold != VenueHold.awaitingReply) e,
    ];

    // "All caught up" is only true once everything has actually loaded.
    final loaded = requests.hasValue && venues.hasValue && partners.hasValue;
    final somethingToDo = waiting.isNotEmpty ||
        partnersWaiting > 0 ||
        inReview > 0 ||
        declined > 0 ||
        drafts > 0;

    String dash(AsyncValue<Object?> value, String Function() shown) =>
        value.hasValue ? shown() : '—';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          l10n.spaceTabOverview,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () => _refresh(ref, range),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // What the person does most, within reach of the thumb.
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.qr_code_scanner_rounded,
                    label: l10n.venueQuickCheckIn,
                    onTap: () => context.go(RouteNames.spaceVenueCheckIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.event_busy_outlined,
                    label: l10n.venueQuickCloseDay,
                    onTap: () => context.go(RouteNames.spaceVenueCalendar),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_business_outlined,
                    label: l10n.venueQuickAddVenue,
                    onTap: () => context.push(RouteNames.spaceVenueStudio),
                  ),
                ),
              ],
            ),
            _SectionHeader(
              title: l10n.overviewAttention,
              action: waiting.isEmpty ? null : l10n.venueSeeAll,
              onAction: () => context.go(RouteNames.spaceVenueRequests),
            ),
            if (loaded && !somethingToDo)
              _AllClear(text: l10n.overviewAllClear),
            for (final request in waiting.take(3)) ...[
              VenueRequestCard(
                request: request,
                onAccept: () => unawaited(
                  answerVenueRequest(context, ref, request, accept: true),
                ),
                onDecline: () => unawaited(
                  answerVenueRequest(context, ref, request, accept: false),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (partnersWaiting > 0)
              _AttentionRow(
                icon: Icons.handshake_outlined,
                color: AppColors.warning,
                text: l10n.overviewPartnersWaiting(partnersWaiting),
                onTap: () => context.push(RouteNames.spaceVenuePartners),
              ),
            if (declined > 0)
              _AttentionRow(
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                text: l10n.overviewVenuesDeclined(declined),
                onTap: () => context.go(RouteNames.spaceVenueVenues),
              ),
            if (inReview > 0)
              _AttentionRow(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.textSecondary,
                text: l10n.overviewVenuesInReview(inReview),
                onTap: () => context.go(RouteNames.spaceVenueVenues),
              ),
            if (drafts > 0)
              _AttentionRow(
                icon: Icons.edit_note_rounded,
                color: AppColors.textSecondary,
                text: l10n.overviewVenuesDrafts(drafts),
                onTap: () => context.go(RouteNames.spaceVenueVenues),
              ),
            _SectionHeader(
              title: l10n.overviewTodayAhead,
              action: ahead.isEmpty ? null : l10n.venueSeeAll,
              onAction: () => context.go(RouteNames.spaceVenueCalendar),
            ),
            if (ahead.isEmpty)
              Text(
                l10n.venueNothingUpcoming,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            else
              for (final entry in ahead.take(4)) ...[
                _UpcomingTile(entry: entry, locale: locale),
                const SizedBox(height: 8),
              ],
            _SectionHeader(title: l10n.overviewNumbers),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Kpi(
                      label: l10n.venueKpiLive,
                      onTap: () => context.go(RouteNames.spaceVenueVenues),
                      value: dash(
                        venues,
                        () => l10n.venueKpiLiveValue(
                          inGroup('live'),
                          myVenues.length,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Kpi(
                      label: l10n.venueKpiUpcoming,
                      onTap: () => context.go(RouteNames.spaceVenueCalendar),
                      value: dash(calendar, () => '${bookings.length}'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Kpi(
                      label: l10n.venueKpiPaid,
                      onTap: () => context.go(RouteNames.spaceVenueEarnings),
                      value: dash(
                        payouts,
                        () => money.format(
                          payouts.requireValue.totals.paid,
                          kBaseCurrency,
                          locale: locale,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Kpi(
                      label: l10n.venueKpiPending,
                      onTap: () => context.go(RouteNames.spaceVenueEarnings),
                      value: dash(
                        payouts,
                        () => money.format(
                          payouts.requireValue.totals.pending,
                          kBaseCurrency,
                          locale: locale,
                        ),
                      ),
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

/// A figure that opens the place where its detail is.
class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(size: 22),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppTypography.body(size: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One thing that needs the person: what it is, and a tap to deal with it.
class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: AppTypography.body())),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when nothing is waiting on the person.
class _AllClear extends StatelessWidget {
  const _AllClear({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.body())),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: AppTypography.label()),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                minimumSize: const Size(0, 36),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// A booking: its day (or "Today"), what it is and when it starts.
class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.entry, required this.locale});

  final CalendarEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final hold = entry.hold;
    final now = DateTime.now();
    final isToday = entry.start.year == now.year &&
        entry.start.month == now.month &&
        entry.start.day == now.day;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: isToday ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  isToday
                      ? context.l10n.overviewToday.toUpperCase()
                      : DateFormat.MMM(locale)
                          .format(entry.start)
                          .toUpperCase(),
                  style: AppTypography.label(
                    color: isToday ? AppColors.accent : AppColors.roleVenue,
                  ),
                ),
                Text(
                  '${entry.start.day}',
                  style: AppTypography.display(size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.jm(locale).format(entry.start),
                  style: AppTypography.body(size: 12),
                ),
              ],
            ),
          ),
          if (hold != null) VenueHoldChip(hold: hold),
        ],
      ),
    );
  }
}

/// A large, thumb-sized shortcut: the icon over its name.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: AppColors.accent),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
