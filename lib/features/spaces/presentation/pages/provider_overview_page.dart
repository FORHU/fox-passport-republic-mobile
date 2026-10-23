import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
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

  Future<void> _addOnWeb(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp(kind.webAdd);
    if (!opened && context.mounted) showTopToast(context, message);
  }

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

    Future<void> refresh() async {
      ref
        ..invalidate(requestsSource)
        ..invalidate(listingsSource)
        ..invalidate(payoutsProvider);
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.inbox_outlined,
                      label: l10n.requestsTitle,
                      badge: waiting.length,
                      onTap: () => context.push(kind.requests),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.inventory_2_outlined,
                      label: listingsLabel(
                        l10n,
                        kind,
                        roles: ref.watch(heldRolesProvider),
                      ),
                      onTap: () => context.go(kind.listings),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.add_circle_outline_rounded,
                      label: l10n.providerAddOnWeb,
                      onTap: () => unawaited(_addOnWeb(context)),
                    ),
                  ),
                ],
              ),
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
            HomeSectionHeader(title: l10n.providerComingUp),
            if (ahead.isEmpty)
              Text(
                l10n.providerNothingComing,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            else
              for (final request in ahead.take(4)) ...[
                _JobTile(request: request, locale: locale),
                const SizedBox(height: 8),
              ],
            HomeSectionHeader(title: l10n.overviewNumbers),
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
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: KpiTile(
                      label: l10n.venueKpiPaid,
                      onTap: () => context.go(kind.earnings),
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
                    child: KpiTile(
                      label: l10n.venueKpiPending,
                      onTap: () => context.go(kind.earnings),
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
