import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:flutter_template/features/gamification/presentation/milestone_labels.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_widgets.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/round_back_button.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The app bar the rewards screens share: back, the [title] (Milestones unless
/// given), and the Tokens chip that opens the Wallet.
PreferredSizeWidget milestonesAppBar(BuildContext context, {String? title}) =>
    AppBar(
      backgroundColor: AppColors.canvas,
      centerTitle: false,
      titleSpacing: 4,
      leadingWidth: 64,
      leading: const RoundBackButton(),
      title: Text(
        title ?? context.l10n.milestonesTitle,
        style: AppTypography.display(size: 26),
      ),
      actions: const [CoinsChip(trailingGap: 16)],
    );

/// The "Find an event to book" button, which opens Search on events.
class FindEventButton extends StatelessWidget {
  const FindEventButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push(RouteNames.searchFor('events')),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(context.l10n.milestonesFindEvent)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Every milestone track, with the reward that is closest at the top. A track
/// opens its journey.
class MilestonesPage extends ConsumerWidget {
  const MilestonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(milestonesProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: milestonesAppBar(context),
      body: summary.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(milestonesProvider),
        ),
        data: (data) => data.milestones.isEmpty
            ? AppStateView(
                kind: AppStateKind.empty,
                title: l10n.milestonesEmpty,
              )
            : _Loaded(summary: data),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.summary});

  final MilestonesSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final closest = summary.closest;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (closest != null) ...[
          _ClosestCard(milestone: closest),
          const SizedBox(height: 20),
        ],
        Text(l10n.milestonesTracks, style: AppTypography.display(size: 18)),
        const SizedBox(height: 4),
        Text(
          l10n.milestonesTracksNote,
          style: AppTypography.body(size: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        for (final m in summary.milestones)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TrackCard(milestone: m),
          ),
      ],
    );
  }
}

/// The reward nearest to being earned: a ring, what is left, what it pays.
class _ClosestCard extends StatelessWidget {
  const _ClosestCard({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = milestone;
    final next = m.next!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.accentTintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: AppRadius.brMd,
            onTap: () => context.push(RouteNames.milestoneJourney(m.key)),
            child: Row(
              children: [
                ProgressRing(
                  size: 84,
                  progress: m.progressPercentage / 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: FittedBox(
                      child: Text(
                        '${milestoneNumber(context, m.currentCount)}'
                        '/${milestoneNumber(context, next.target)}',
                        style: AppTypography.display(size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.milestonesClosest.toUpperCase(),
                        style: AppTypography.body(
                          size: 11,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        milestoneMoreLabel(context, m, m.remaining),
                        style: AppTypography.display(size: 20),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          RewardChip(
                            label: l10n.milestonesTokensReward(next.tokens),
                          ),
                          if (next.badgeName != null)
                            RewardChip(
                              accent: false,
                              label: l10n.milestonesBadgeReward(
                                next.badgeName!,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const FindEventButton(),
        ],
      ),
    );
  }
}

/// One track: its name, tier dots and what is left to the next tier.
class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = milestone;
    final next = m.next;
    return Semantics(
      button: true,
      label: l10n.milestonesTabLabel(m.name),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push(RouteNames.milestoneJourney(m.key)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FoxEmblem(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(size: 15),
                        ),
                        Text(
                          milestoneUnitLabel(context, m, m.currentCount),
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
                  Text(
                    l10n
                        .milestonesTierOfTotal(m.currentTier, m.tiers.length)
                        .toUpperCase(),
                    style: AppTypography.body(
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TierDots(milestone: m),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      next == null
                          ? l10n.milestonesAllReached
                          : l10n.milestonesToReachTier(
                              milestoneShortMoreLabel(context, m, m.remaining),
                              next.tier,
                            ),
                      style: AppTypography.body(
                        size: 12,
                      ),
                    ),
                  ),
                  if (next != null) ...[
                    const SizedBox(width: 8),
                    RewardChip(label: l10n.milestonesTokensReward(next.tokens)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
