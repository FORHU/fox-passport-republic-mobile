import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:flutter_template/features/gamification/presentation/milestone_labels.dart';
import 'package:flutter_template/features/gamification/presentation/pages/milestones_page.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_badge.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_widgets.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/pill_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One track at a time: tabs to switch track without going back, a ring, and
/// the tiers as cards to swipe or pick with the dots.
class MilestoneJourneyPage extends ConsumerStatefulWidget {
  const MilestoneJourneyPage({required this.milestoneKey, super.key});

  /// The track the screen opens on.
  final String milestoneKey;

  @override
  ConsumerState<MilestoneJourneyPage> createState() =>
      _MilestoneJourneyPageState();
}

class _MilestoneJourneyPageState extends ConsumerState<MilestoneJourneyPage> {
  late String _key = widget.milestoneKey;

  @override
  Widget build(BuildContext context) {
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
        data: (data) {
          // An unknown key (a stale link) falls back to the first track.
          final m = data.byKey(_key) ??
              (data.milestones.isEmpty ? null : data.milestones.first);
          if (m == null) {
            return AppStateView(
              kind: AppStateKind.empty,
              title: l10n.milestonesEmpty,
            );
          }
          return _Loaded(
            summary: data,
            milestone: m,
            onPick: (key) => setState(() => _key = key),
          );
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.summary,
    required this.milestone,
    required this.onPick,
  });

  final MilestonesSummary summary;
  final Milestone milestone;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = milestone;
    final next = m.next;
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: summary.milestones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = summary.milestones[i];
              return PillChip(
                label: t.name,
                selected: t.key == m.key,
                onTap: () => onPick(t.key),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Center(
                child: ProgressRing(
                  size: 168,
                  strokeWidth: 10,
                  progress: m.progressPercentage / 100,
                  child: MilestoneBadge(
                    rarity: (next?.tier ?? m.tiers.length) - 1,
                    size: 96,
                    state: next == null
                        ? MilestoneBadgeState.earned
                        : MilestoneBadgeState.next,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // "3 / 5 BOOKED", the count under the ring.
              Center(child: _CountPill(milestone: m)),
              const SizedBox(height: 14),
              Text(
                next == null
                    ? l10n.milestonesAllReached
                    : next.badgeName == null
                        ? milestoneMoreLabel(context, m, m.remaining)
                        : l10n.milestonesMoreToBadge(
                            milestoneShortMoreLabel(context, m, m.remaining),
                            next.badgeName!,
                          ),
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 22),
              ),
              if (next != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: RewardChip(
                    label: l10n.milestonesTokensReward(next.tokens),
                  ),
                ),
              ],
              if (m.counter == 'booked_events') ...[
                const SizedBox(height: 8),
                Text(
                  l10n.milestonesPaidNote,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.milestonesJourney,
                      style: AppTypography.display(size: 18),
                    ),
                  ),
                  Text(
                    l10n.milestonesJourneyTotal(m.totalTokens),
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // A new track gets a new pager, so it opens on its own next tier.
              _TierPager(key: ValueKey(m.key), milestone: m),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: const FindEventButton(),
        ),
      ],
    );
  }
}

/// The tier cards, swiped sideways, with "Tier 2 of 5" and tappable dots under
/// them so the swipe is never the only way.
class _TierPager extends StatefulWidget {
  const _TierPager({required this.milestone, super.key});

  final Milestone milestone;

  @override
  State<_TierPager> createState() => _TierPagerState();
}

class _TierPagerState extends State<_TierPager> {
  late final int _start = _openingIndex(widget.milestone);
  late final PageController _controller =
      PageController(initialPage: _start, viewportFraction: 0.62);
  late int _index = _start;

  /// Opens on the next tier to reach, or the last one once all are reached.
  static int _openingIndex(Milestone m) {
    if (m.tiers.isEmpty) return 0;
    final i = m.tiers.indexWhere((t) => t.tier == m.nextTier);
    return i < 0 ? m.tiers.length - 1 : i;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = widget.milestone;
    if (m.tiers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        // The nodes come first, as in the design: they are the journey, and
        // each one picks its tier.
        TierBadgeRow(milestone: m, selected: _index, onTap: _goTo),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: m.tiers.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TierCard(milestone: m, tier: m.tiers[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.milestonesTierPosition(m.tiers[_index].tier, m.tiers.length),
          style: AppTypography.body(size: 13),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.milestonesSwipeHint,
          textAlign: TextAlign.center,
          style: AppTypography.body(size: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// "3 / 5 BOOKED" under the ring: the count, the next target and what is
/// counted. Once every tier is reached it is just the count.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.milestone});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final next = m.next;
    final count = milestoneNumber(context, m.currentCount);
    final label = next == null
        ? count
        : '$count / ${milestoneNumber(context, next.target)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentTintBg,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.accentTintBorder),
      ),
      child: Text(
        '$label ${milestoneWord(context, m)}'.toUpperCase(),
        style: AppTypography.body(size: 12, color: AppColors.accent),
      ),
    );
  }
}

/// One tier: reached, next up or locked, what it asks and what it pays.
class _TierCard extends StatelessWidget {
  const _TierCard({required this.milestone, required this.tier});

  final Milestone milestone;
  final MilestoneTier tier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isNext = tier.tier == milestone.nextTier;
    final status = tier.isReached
        ? l10n.milestonesReached
        : isNext
            ? l10n.milestonesNextUp
            : l10n.milestonesLocked;
    final color = tier.isReached
        ? AppColors.success
        : isNext
            ? AppColors.accent
            : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: isNext ? AppColors.accentTintBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tier.isReached
                    ? Icons.check_rounded
                    : isNext
                        ? Icons.arrow_forward_rounded
                        : Icons.lock_outline_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                status.toUpperCase(),
                style: AppTypography.body(size: 11, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            milestoneUnitLabel(context, milestone, tier.target),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(size: 18),
          ),
          if (isNext) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: milestone.progressPercentage / 100,
                minHeight: 6,
                color: AppColors.accent,
                backgroundColor: AppColors.border,
              ),
            ),
          ],
          const Spacer(),
          Text(
            l10n.milestonesTokensReward(tier.tokens),
            style: AppTypography.body(size: 13, color: AppColors.textPrimary),
          ),
          if (tier.badgeName != null)
            Text(
              l10n.milestonesBadgeReward(tier.badgeName!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
