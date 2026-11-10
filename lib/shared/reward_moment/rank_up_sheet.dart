import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/rank_info.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Shows the sheet for a new rank. [rankName] is the name the server gave the
/// rank now held and [level] the level reached. Completes with true when the
/// person chose to see their badges.
Future<bool?> showRankUpSheet(
  BuildContext context, {
  required RankUpMoment rankUp,
  required String rankName,
  required int level,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RankUpSheet(
        rankUp: rankUp,
        rankName: rankName,
        level: level,
      ),
    );

/// The old badge becomes the new one, with the Coins the rank paid and how far
/// it is to the next. The badge change plays once; with reduced motion the new
/// badge is simply there.
class RankUpSheet extends StatelessWidget {
  const RankUpSheet({
    required this.rankUp,
    required this.rankName,
    required this.level,
    super.key,
  });

  final RankUpMoment rankUp;
  final String rankName;
  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final still = MediaQuery.of(context).disableAnimations;
    final coins = rankUpCoinsFor(rankUp.toRank);
    final next = nextRankName(rankName);
    final nextLevel = minLevelOfRank(rankUp.toRank + 1);

    Widget fresh = RankBadge(
      rank: rankUp.toRank,
      size: 132,
      label: rankName,
    );
    Widget old = Opacity(
      opacity: 0.55,
      child: RankBadge(rank: rankUp.fromRank, size: 56),
    );
    if (!still) {
      old = old
          .animate()
          .fadeIn(duration: 200.ms)
          .then(delay: 350.ms)
          .fadeOut(duration: 300.ms);
      fresh = fresh
          .animate(delay: 450.ms)
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 450.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 300.ms);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.brPill,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.rankUpEyebrow.toUpperCase(),
              style: AppTypography.label(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                old,
                const SizedBox(width: 14),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 14),
                fresh,
              ],
            ),
            const SizedBox(height: 12),
            Text(rankName, style: AppTypography.display(size: 32)),
            const SizedBox(height: 4),
            Text(
              l10n.rankUpLevelRank(level, rankUp.toRank, rankCount),
              style: AppTypography.body(),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (coins > 0)
                  _Chip(
                    label: l10n.rankUpCoins(format.format(coins)),
                    color: AppColors.textPrimary,
                    icon: coinsIcon,
                    dark: true,
                  ),
                _Chip(label: l10n.rankUpNewBadge, color: AppColors.violet),
              ],
            ),
            if (next != null && nextLevel != null) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.rankUpNext(next),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.rankUpNextLevel(nextLevel),
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadius.brPill,
                child: LinearProgressIndicator(
                  // Never quite empty: a sliver shows the bar is there.
                  value: math.max(0.05, rankProgress(level)),
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: const AlwaysStoppedAnimation(AppColors.violet),
                ),
              ),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: l10n.rankUpSeeBadges,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: l10n.rewardMomentDone,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.dark = false,
  });

  final String label;
  final Color color;

  /// Before the words, such as the Coins icon.
  final IconData? icon;

  /// Dark with a plain border, instead of tinted with [color].
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? AppColors.canvas : color.withValues(alpha: 0.14),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: dark ? AppColors.border : color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(size: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
