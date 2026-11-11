import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/domain/achievements.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One achievement: its name and three tier marks, what it asks, how far the
/// person is, and what the next tier pays.
class AchievementCard extends StatelessWidget {
  const AchievementCard({required this.achievement, super.key});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = achievement;
    final next = a.next;
    final percent = a.isCompleted ? 100 : a.progressPercentage.round();
    return Container(
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
              Expanded(
                child: Text(a.name, style: AppTypography.display()),
              ),
              for (final tier in a.tiers) ...[
                const SizedBox(width: 6),
                _TierPip(tier: tier),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            a.description,
            style: AppTypography.body(size: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                a.isCompleted
                    ? l10n.achievementsComplete
                    : l10n.achievementsCount(a.currentCount, a.targetCount),
                style: AppTypography.display(size: 13),
              ),
              const Spacer(),
              Text(
                l10n.achievementsPercent(percent),
                style: AppTypography.body(size: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(AppColors.violet),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 12),
            _Rewards(tier: next, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

/// "I", "II" or "III": a check once reached, an outline until then.
class _TierPip extends StatelessWidget {
  const _TierPip({required this.tier});

  final AchievementTier tier;

  static const _numerals = ['I', 'II', 'III'];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final numeral = _numerals[(tier.tier - 1).clamp(0, 2)];
    return Semantics(
      label: tier.isUnlocked
          ? l10n.achievementsTierDone(tier.tier)
          : l10n.achievementsTierTodo(tier.tier),
      child: ExcludeSemantics(
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tier.isUnlocked ? AppColors.violet : Colors.transparent,
            border: Border.all(
              color: tier.isUnlocked ? AppColors.violet : AppColors.border,
            ),
          ),
          child: tier.isUnlocked
              ? const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                )
              : Text(
                  numeral,
                  style: AppTypography.body(
                    size: 10,
                    color: AppColors.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

/// What the next tier pays: Tokens and a badge, each when it has one.
class _Rewards extends StatelessWidget {
  const _Rewards({required this.tier, required this.l10n});

  final AchievementTier tier;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (tier.coins > 0)
          _Reward(
            label: l10n.achievementsRewardCoins(tier.coins),
            color: AppColors.textSecondary,
          ),
        if (tier.badgeName != null)
          _Reward(
            label: l10n.achievementsRewardBadge(tier.badgeName!),
            color: AppColors.textSecondary,
          ),
      ],
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.brPill,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: AppTypography.display(size: 12),
      ),
    );
  }
}
