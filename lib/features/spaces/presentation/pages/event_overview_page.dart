import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/earnings_trend.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/earnings_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/featured_photo_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/first_steps_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/overview_header.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// The Event space's first screen, laid out like every other Foxer space: a
/// greeting with the role, the first steps for someone new, what the person
/// does most, and what needs them (venue invitations, and events in review,
/// declined or unfinished). The events themselves are on the Events tab.
class EventOverviewPage extends ConsumerWidget {
  const EventOverviewPage({super.key});

  /// Setting up payouts takes bank and identity details, so it is finished on
  /// the web, as it is from Earnings.
  Future<void> _setUpPayouts(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp('/creator-dashboard/stripe-onboard');
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(myEventsProvider);
    final invites = ref.watch(partnersWaitingProvider(PartnerSide.eventFoxer));
    final partners = ref.watch(partnersProvider);
    final stripe = ref.watch(stripeStatusProvider);
    final payouts = ref.watch(payoutsProvider);
    final money = ref.watch(moneyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final isNew =
        ref.watch(newFoxerProvider(NewFoxerSpace.event)).asData?.value ?? false;

    final all = events.asData?.value ?? const [];
    int inGroup(String group) => all.where((e) => e.group == group).length;
    final inReview = inGroup('pending');
    final declined = inGroup('rejected');
    final drafts = inGroup('draft');
    final somethingToDo =
        invites > 0 || inReview > 0 || declined > 0 || drafts > 0;

    // Opens the Events tab on one status group.
    void showGroup(String group) =>
        context.go('${RouteNames.spaceEventList}?group=$group');

    // What a new Event Foxer does first; each step ticks itself off from real
    // data, and the card shows once everything it reads has loaded.
    final firstSteps = [
      FirstStep(
        label: l10n.firstStepHost,
        done: partners.asData?.value.asEventFoxer.any(
              (p) => p.status == PartnerStatus.approved,
            ) ??
            false,
        onTap: () => context.push(RouteNames.spaceEventPartners),
      ),
      FirstStep(
        label: l10n.firstStepEvent,
        done: all.isNotEmpty,
        onTap: () => context.push(RouteNames.spaceEventStudio),
      ),
      FirstStep(
        label: l10n.firstStepPayout,
        done: stripe.asData?.value.onboardingComplete ?? false,
        onTap: () => unawaited(_setUpPayouts(context)),
      ),
    ];
    final stepsLoaded =
        isNew && events.hasValue && partners.hasValue && stripe.hasValue;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.spaceTabOverview),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref
            ..invalidate(partnersProvider)
            ..invalidate(stripeStatusProvider)
            ..invalidate(myEventsProvider);
          try {
            await ref.read(myEventsProvider.future);
          } on Object {
            // The Events tab shows its own error state with a retry.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const OverviewGreeting(),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(RouteNames.spaceEventCalendar),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(l10n.spaceTabCalendar),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(RouteNames.spaceEventStudio),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: Text(l10n.eventsNewOnWeb),
                  ),
                ),
              ],
            ),
            HomeSectionHeader(title: l10n.overviewAttention),
            if (partners.hasValue && events.hasValue && !somethingToDo)
              AllClearCard(text: l10n.overviewAllClear),
            if (invites > 0)
              AttentionRow(
                icon: Icons.mail_outline_rounded,
                color: AppColors.warning,
                text: l10n.eventsInvitesWaiting(invites),
                onTap: () => context.push(RouteNames.spaceEventPartners),
              ),
            if (declined > 0)
              AttentionRow(
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                text: l10n.eventsDeclined(declined),
                onTap: () => showGroup('rejected'),
              ),
            if (inReview > 0)
              AttentionRow(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.textSecondary,
                text: l10n.eventsInReview(inReview),
                onTap: () => showGroup('pending'),
              ),
            if (drafts > 0)
              AttentionRow(
                icon: Icons.edit_note_rounded,
                color: AppColors.textSecondary,
                text: l10n.eventsDrafts(drafts),
                onTap: () => showGroup('draft'),
              ),
            if (stepsLoaded) ...[
              const SizedBox(height: 10),
              FirstStepsCard(steps: firstSteps, collapseWhenStarted: true),
              const SizedBox(height: 10),
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
                weeks: p.rows.length < 3
                    ? null
                    : weeklyPaid(p.rows, DateTime.now()),
                onTap: () => context.go(RouteNames.spaceEventEarnings),
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: KpiTile(
                      label: l10n.eventKpiLive,
                      onTap: () => context.go(RouteNames.spaceEventList),
                      value: events.hasValue
                          ? l10n.venueKpiLiveValue(inGroup('live'), all.length)
                          : '—',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KpiTile(
                      label: l10n.listingStatusPending,
                      onTap: () => showGroup('pending'),
                      value: events.hasValue ? '$inReview' : '—',
                    ),
                  ),
                ],
              ),
            ),
            if (all.isNotEmpty) ...[
              HomeSectionHeader(
                title: l10n.overviewMyEvents,
                action: l10n.venueViewAll,
                onAction: () => context.go(RouteNames.spaceEventList),
              ),
              for (final event in all.take(2)) ...[
                GestureDetector(
                  onTap: () => context.push(
                    RouteNames.spaceEventStudioEdit(event.id),
                  ),
                  child: FeaturedPhotoCard(
                    dayLabel: (listingStatusLabel(l10n, event.status) ?? '')
                        .toUpperCase(),
                    title: event.name,
                    subtitle: event.city,
                    imageUrl: event.imageUrl,
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
