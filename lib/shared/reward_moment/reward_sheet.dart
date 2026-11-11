import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// What the person chose on the reward sheet.
enum RewardSheetChoice { viewPassport, learnMore }

/// The sheet shown after Tokens arrive: what they were for and how much. Pops
/// with [RewardSheetChoice] when a button
/// other than Done is pressed, so the caller can navigate once it has closed.
Future<RewardSheetChoice?> showRewardSheet(
  BuildContext context, {
  required RewardMoment reward,
  String? eventName,
}) =>
    showModalBottomSheet<RewardSheetChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RewardSheet(
        reward: reward,
        eventName: eventName,
      ),
    );

/// The words for what was rewarded.
String rewardMomentTitle(
  AppLocalizations l10n,
  RewardMoment reward, {
  String? eventName,
}) =>
    switch (reward.action) {
      'attend_event' => eventName == null
          ? l10n.rewardMomentAttended
          : l10n.rewardMomentAttendedAt(eventName),
      'leave_review' || 'five_star_review' => l10n.rewardMomentReview,
      _ => l10n.rewardMomentGeneric,
    };

class RewardSheet extends StatelessWidget {
  const RewardSheet({
    required this.reward,
    this.eventName,
    super.key,
  });

  final RewardMoment reward;

  /// The event it was for, when it could be found; the title is then "You
  /// attended Rooftop Sessions", and the new stamp is named.
  final String? eventName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final attended = reward.action == 'attend_event';
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
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 30,
              ),
            ),
            if (attended) ...[
              const SizedBox(height: 14),
              Text(
                l10n.rewardMomentCheckedIn.toUpperCase(),
                style: AppTypography.label(),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              rewardMomentTitle(l10n, reward, eventName: eventName),
              textAlign: TextAlign.center,
              style: AppTypography.display(size: 24),
            ),
            const SizedBox(height: 20),
            if (reward.coins > 0)
              _Amount(
                icon: coinsIcon,
                label: l10n.rewardMomentCoins,
                value: '+${format.format(reward.coins)}',
                color: AppColors.textSecondary,
              ),
            // Attending is what earns a stamp, in the same step.
            if (attended && eventName != null) ...[
              const SizedBox(height: 14),
              _StampRow(eventName: eventName!),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.rewardMomentNote,
                      style: AppTypography.body(
                        size: 12,
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 0,
                    child: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pop(RewardSheetChoice.learnMore),
                      child: Text(
                        l10n.rewardMomentLearnMore,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.rewardMomentViewPassport,
              onPressed: () =>
                  Navigator.of(context).pop(RewardSheetChoice.viewPassport),
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

/// "New stamp added" and the event it is for.
class _StampRow extends StatelessWidget {
  const _StampRow({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.rewardMomentNewStamp,
                  style: AppTypography.display(size: 14),
                ),
                Text(
                  eventName,
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
        ],
      ),
    );
  }
}

/// "+40 Tokens" in a tile.
class _Amount extends StatelessWidget {
  const _Amount({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: AppRadius.brMd,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label(color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(value, style: AppTypography.display(size: 30)),
            ],
          ),
        ),
      ),
    );
  }
}
