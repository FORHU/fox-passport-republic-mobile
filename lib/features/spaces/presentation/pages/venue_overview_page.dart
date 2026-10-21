import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/widgets/venue_hold_chip.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
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

/// The Venue space's first screen: the numbers that matter, what is waiting
/// for a reply (answered here, without opening anything), what is coming up at
/// the person's venues, and the things they do most.
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

    final waiting = [
      ...?requests.asData?.value.where((r) => r.needsReply),
    ];
    final upcoming = [
      ...?calendar.asData?.value.where(
        (e) => e.role == CalendarRole.venue && !e.isBlock && e.hold != null,
      ),
    ];
    // What is still ahead and settled or held; the ones waiting for a reply are
    // already above.
    final comingUp = [
      for (final e in upcoming)
        if (e.hold != VenueHold.awaitingReply) e,
    ];

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
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    label: l10n.venueKpiLive,
                    value: dash(venues, () {
                      final list = venues.requireValue;
                      final live = list
                          .where(
                            (v) =>
                                v.status == 'available' ||
                                v.status == 'published',
                          )
                          .length;
                      return l10n.venueKpiLiveValue(live, list.length);
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Kpi(
                    label: l10n.venueKpiUpcoming,
                    value: dash(calendar, () => '${upcoming.length}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Kpi(
                    label: l10n.venueKpiPaid,
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
            _SectionHeader(
              title: l10n.venueNeedsReply,
              action: waiting.isEmpty ? null : l10n.venueSeeAll,
              onAction: () => context.go(RouteNames.spaceVenueRequests),
            ),
            if (waiting.isEmpty)
              Text(
                l10n.venueNothingWaiting,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            else
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
            _SectionHeader(
              title: l10n.venueComingUp,
              action: comingUp.isEmpty ? null : l10n.venueSeeAll,
              onAction: () => context.go(RouteNames.spaceVenueCalendar),
            ),
            if (comingUp.isEmpty)
              Text(
                l10n.venueNothingUpcoming,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            else
              for (final entry in comingUp.take(3)) ...[
                _UpcomingTile(entry: entry, locale: locale),
                const SizedBox(height: 8),
              ],
            _SectionHeader(title: l10n.venueQuickActions),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: l10n.venueQuickCheckIn,
                  onTap: () => context.go(RouteNames.spaceVenueCheckIn),
                ),
                _QuickAction(
                  icon: Icons.event_busy_outlined,
                  label: l10n.venueQuickCloseDay,
                  onTap: () => context.go(RouteNames.spaceVenueCalendar),
                ),
                _QuickAction(
                  icon: Icons.add_business_outlined,
                  label: l10n.venueQuickAddVenue,
                  onTap: () => context.push(RouteNames.spaceVenueStudio),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
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

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.entry, required this.locale});

  final CalendarEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final hold = entry.hold;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  DateFormat.MMM(locale).format(entry.start).toUpperCase(),
                  style: AppTypography.label(color: AppColors.roleVenue),
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
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: AppColors.accent),
      label: Text(label),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
    );
  }
}
