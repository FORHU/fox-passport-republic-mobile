import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/earnings_trend.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/earnings_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/featured_photo_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/first_steps_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_status.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/overview_header.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The Provider space's home: the requests that need a reply, what is
/// confirmed and coming up, and the numbers. For someone who lists gear,
/// services or performances.
class ProviderOverviewPage extends ConsumerWidget {
  const ProviderOverviewPage({required this.kind, super.key});

  /// Gear or services: what this space is for.
  final ProviderKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);

    final requestsSource = supplyRequestsProvider(kind.request);
    final listingsSource = kind.isGear ? myAssetsProvider : myServicesProvider;
    final requests = ref.watch(requestsSource);
    final items = ref.watch(listingsSource);
    final payouts = ref.watch(payoutsProvider);
    final stripe = ref.watch(stripeStatusProvider);
    final roles = ref.watch(heldRolesProvider);
    final isNew = ref
            .watch(
              newFoxerProvider(
                kind.isGear ? NewFoxerSpace.gear : NewFoxerSpace.services,
              ),
            )
            .asData
            ?.value ??
        false;

    final all = requests.asData?.value ?? const <VenueRequest>[];
    final waiting = [
      for (final r in all)
        if (r.needsReply) r,
    ];
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 30));
    // Confirmed and still ahead, soonest first.
    final ahead = [
      for (final r in all)
        if (r.status == RequestStatus.approved &&
            r.startAt != null &&
            r.startAt!.isAfter(now.subtract(const Duration(days: 1))))
          r,
    ]..sort((a, b) => a.startAt!.compareTo(b.startAt!));
    final inMonth = ahead.where((r) => r.startAt!.isBefore(horizon)).length;

    final listings = items.asData?.value ?? const <SpaceListing>[];
    final live = listings.where((l) => l.group == 'live').length;
    final loaded = requests.hasValue && items.hasValue;

    String dash(AsyncValue<Object?> value, String Function() shown) =>
        value.hasValue ? shown() : '—';

    // Who this space is for, and what they do first. Both follow the roles
    // held: a Performer who is not also a Talent sees the Performer wording.
    final performerOnly = !kind.isGear &&
        roles.contains('performerFoxer') &&
        !roles.contains('serviceFoxer');
    final addLabel = kind.isGear
        ? l10n.providerAddGear
        : performerOnly
            ? l10n.providerAddPerformance
            : l10n.providerAddService;
    final myLabel = kind.isGear
        ? l10n.overviewMyGear
        : performerOnly
            ? l10n.overviewMyPerformances
            : l10n.overviewMyServices;
    final firstSteps = [
      FirstStep(
        label: kind.isGear
            ? l10n.firstStepGear
            : performerOnly
                ? l10n.firstStepPerformance
                : l10n.firstStepService,
        done: listings.isNotEmpty,
        onTap: () => unawaited(context.push(kind.studio)),
      ),
      FirstStep(
        label: l10n.firstStepPayout,
        done: stripe.asData?.value.onboardingComplete ?? false,
        onTap: () => context.go(kind.earnings),
      ),
    ];
    final stepsLoaded = isNew && items.hasValue && stripe.hasValue;

    Future<void> refresh() async {
      ref
        ..invalidate(requestsSource)
        ..invalidate(listingsSource)
        ..invalidate(payoutsProvider)
        ..invalidate(stripeStatusProvider);
      try {
        await ref.read(requestsSource.future);
      } on Object {
        // The page shows what it has; the tiles read "—" for the rest.
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.spaceTabOverview),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: refresh,
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
                    onPressed: () => context.go(kind.calendar),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(l10n.spaceTabCalendar),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => unawaited(context.push(kind.studio)),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: Text(addLabel),
                  ),
                ),
              ],
            ),
            HomeSectionHeader(title: l10n.overviewAttention),
            if (loaded && waiting.isEmpty)
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
              const SizedBox(height: 12),
            ],
            if (waiting.length > 3)
              AttentionRow(
                icon: Icons.inbox_outlined,
                color: AppColors.warning,
                text: l10n.providerRequestsWaiting(waiting.length),
                onTap: () => context.push(kind.requests),
              ),
            if (stepsLoaded) ...[
              const SizedBox(height: 10),
              FirstStepsCard(steps: firstSteps, collapseWhenStarted: true),
              const SizedBox(height: 10),
            ],
            HomeSectionHeader(title: l10n.providerComingUp),
            if (ahead.isEmpty)
              Text(
                l10n.providerNothingComing,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            else
              for (final (i, request) in ahead.take(4).indexed) ...[
                // The first is led by a photo of what is supplied.
                if (i == 0)
                  FeaturedPhotoCard(
                    dayLabel: DateFormat('EEE d MMM', locale)
                        .format(request.startAt!)
                        .toUpperCase(),
                    title: request.venueName,
                    subtitle: request.eventName,
                    imageUrl: request.imageUrl,
                  )
                else
                  _JobTile(request: request, locale: locale),
                const SizedBox(height: 8),
              ],
            HomeSectionHeader(title: l10n.overviewNumbers),
            payouts.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => EarningsCard(
                paid:
                    money.format(p.totals.paid, kBaseCurrency, locale: locale),
                pending: money.format(p.totals.pending, kBaseCurrency,
                    locale: locale,),
                change: monthChange(p.rows, DateTime.now()),
                weeks: p.rows.length < 3
                    ? null
                    : weeklyPaid(p.rows, DateTime.now()),
                onTap: () => context.go(kind.earnings),
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: KpiTile(
                      label: l10n.providerStatLive,
                      onTap: () => context.go(kind.listings),
                      value: loaded ? '$live / ${listings.length}' : '—',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: KpiTile(
                      label: l10n.providerStatJobs,
                      onTap: () => context.go(kind.calendar),
                      value: dash(requests, () => '$inMonth'),
                    ),
                  ),
                ],
              ),
            ),
            if (listings.isNotEmpty) ...[
              HomeSectionHeader(
                title: myLabel,
                action: l10n.venueViewAll,
                onAction: () => context.go(kind.listings),
              ),
              for (final item in listings.take(2)) ...[
                GestureDetector(
                  onTap: () => unawaited(context.push(kind.studioFor(item.id))),
                  child: FeaturedPhotoCard(
                    dayLabel: (listingStatusLabel(l10n, item.status) ?? '')
                        .toUpperCase(),
                    title: item.name,
                    subtitle: item.city,
                    imageUrl: item.imageUrl,
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

/// A confirmed job: its day, what is supplied, and for which event.
class _JobTile extends StatelessWidget {
  const _JobTile({required this.request, required this.locale});

  final VenueRequest request;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final start = request.startAt!;
    final day = DateFormat('EEE d MMM', locale).format(start);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  request.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 14),
                ),
                Text(
                  request.eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(day, style: AppTypography.label(color: AppColors.accent)),
        ],
      ),
    );
  }
}
