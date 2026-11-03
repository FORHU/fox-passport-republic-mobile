import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/widgets/venue_hold_chip.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/earnings_trend.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/earnings_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/featured_photo_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/first_steps_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/overview_header.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
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
      ..invalidate(stripeStatusProvider)
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
    final stripe = ref.watch(stripeStatusProvider);
    final isNew =
        ref.watch(newFoxerProvider(NewFoxerSpace.venue)).asData?.value ?? false;

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

    // The first steps tick themselves off from real data, and show only once
    // everything they read has loaded.
    final firstSteps = [
      FirstStep(
        label: l10n.firstStepVenue,
        done: myVenues.isNotEmpty,
        onTap: () => context.push(RouteNames.spaceVenueStudio),
      ),
      FirstStep(
        label: l10n.firstStepPayout,
        done: stripe.asData?.value.onboardingComplete ?? false,
        onTap: () => context.go(RouteNames.spaceVenueEarnings),
      ),
      FirstStep(
        label: l10n.firstStepPartner,
        done: partners.asData?.value.asMayor.any(
              (p) => p.status == PartnerStatus.approved,
            ) ??
            false,
        onTap: () => context.push(RouteNames.spaceVenuePartners),
      ),
    ];
    final stepsLoaded =
        isNew && venues.hasValue && partners.hasValue && stripe.hasValue;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.spaceTabOverview),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () => _refresh(ref, range),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            OverviewGreeting(
              roleLabel: l10n.overviewRoleVenue,
              roleColor: AppColors.roleVenue,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(RouteNames.spaceVenueCalendar),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(l10n.spaceTabCalendar),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(RouteNames.spaceVenueStudio),
                    icon: const Icon(Icons.add_business_outlined),
                    label: Text(l10n.venueQuickAddVenue),
                  ),
                ),
              ],
            ),
            HomeSectionHeader(
              title: l10n.overviewAttention,
              action: waiting.isEmpty ? null : l10n.venueSeeAll,
              onAction: () => context.go(RouteNames.spaceVenueRequests),
            ),
            if (loaded && !somethingToDo)
              AllClearCard(text: l10n.overviewAllClear),
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
              AttentionRow(
                icon: Icons.handshake_outlined,
                color: AppColors.warning,
                text: l10n.overviewPartnersWaiting(partnersWaiting),
                onTap: () => context.push(RouteNames.spaceVenuePartners),
              ),
            if (declined > 0)
              AttentionRow(
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                text: l10n.overviewVenuesDeclined(declined),
                onTap: () => context.go(RouteNames.spaceVenueVenues),
              ),
            if (inReview > 0)
              AttentionRow(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.textSecondary,
                text: l10n.overviewVenuesInReview(inReview),
                onTap: () => context.go(RouteNames.spaceVenueVenues),
              ),
            if (drafts > 0)
              AttentionRow(
                icon: Icons.edit_note_rounded,
                color: AppColors.textSecondary,
                text: l10n.overviewVenuesDrafts(drafts),
                onTap: () => context.go(RouteNames.spaceVenueVenues),
              ),
            if (stepsLoaded) ...[
              const SizedBox(height: 10),
              FirstStepsCard(steps: firstSteps, collapseWhenStarted: true),
              const SizedBox(height: 10),
            ],
            HomeSectionHeader(
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
              for (final (i, entry) in ahead.take(4).indexed) ...[
                // The first is led by a photo of its venue.
                if (i == 0)
                  _featuredBooking(
                    context,
                    entry,
                    locale,
                    myVenues
                        .where((v) => v.id == entry.venueId)
                        .firstOrNull
                        ?.imageUrl,
                  )
                else
                  _UpcomingTile(entry: entry, locale: locale),
                const SizedBox(height: 8),
              ],
            HomeSectionHeader(title: l10n.overviewNumbers),
            payouts.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => EarningsCard(
                paid:
                    money.format(p.totals.paid, kBaseCurrency, locale: locale),
                pending: money.format(
                  p.totals.pending,
                  kBaseCurrency,
                  locale: locale,
                ),
                change: monthChange(p.rows, DateTime.now()),
                // A chart of nearly nothing says nothing.
                weeks: p.rows.length < 3
                    ? null
                    : weeklyPaid(p.rows, DateTime.now()),
                onTap: () => context.go(RouteNames.spaceVenueEarnings),
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: KpiTile(
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
                    child: KpiTile(
                      label: l10n.venueKpiUpcoming,
                      onTap: () => context.go(RouteNames.spaceVenueCalendar),
                      value: dash(calendar, () => '${bookings.length}'),
                    ),
                  ),
                ],
              ),
            ),
            if (myVenues.isNotEmpty) ...[
              HomeSectionHeader(
                title: l10n.overviewMyVenues,
                action: l10n.venueViewAll,
                onAction: () => context.go(RouteNames.spaceVenueVenues),
              ),
              for (final venue in myVenues.take(2)) ...[
                GestureDetector(
                  onTap: () => context.push(RouteNames.spaceVenueHub(venue.id)),
                  child: FeaturedPhotoCard(
                    dayLabel: (listingStatusLabel(l10n, venue.status) ?? '')
                        .toUpperCase(),
                    title: venue.name,
                    subtitle: venue.city,
                    imageUrl: venue.imageUrl,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// The next booking as a photo card: its day, what it is, where and when.
Widget _featuredBooking(
  BuildContext context,
  CalendarEntry entry,
  String locale,
  String? imageUrl,
) {
  final now = DateTime.now();
  final isToday = entry.start.year == now.year &&
      entry.start.month == now.month &&
      entry.start.day == now.day;
  final where = entry.venueName;
  final when = DateFormat.jm(locale).format(entry.start);
  final hold = entry.hold;
  return FeaturedPhotoCard(
    dayLabel: isToday
        ? context.l10n.overviewToday.toUpperCase()
        : DateFormat.MMMd(locale).format(entry.start).toUpperCase(),
    title: entry.title,
    subtitle: where == null || where.isEmpty ? when : '$where · $when',
    imageUrl: imageUrl,
    highlight: isToday,
    statusChip: hold == null ? null : VenueHoldChip(hold: hold),
  );
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
