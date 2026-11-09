import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/foxers/foxer_score.dart';
import 'package:flutter_template/shared/foxers/foxer_score_source.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The Foxer's own Foxer Score, out of 100, with the five parts behind it and
/// the facts they come from. For the Foxer's Passport only: guests never see
/// the score, only the rating, the facts and the labels. It takes no room
/// until the server has answered, and nothing shows if it fails.
class FoxerScoreCard extends ConsumerWidget {
  const FoxerScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(myFoxerScoreProvider).value;
    if (score == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final b = score.breakdown;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    l10n.foxerScoreTitle,
                    style: AppTypography.display(),
                  ),
                ),
                Text(
                  l10n.foxerScoreOutOf(score.score),
                  style: AppTypography.display(size: 24),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: score.score / 100,
                minHeight: 8,
                backgroundColor: AppColors.surfaceRaised,
                valueColor: const AlwaysStoppedAnimation(AppColors.violet),
              ),
            ),
            const SizedBox(height: 14),
            _Part(
              label: l10n.foxerScorePartRating,
              value: b.rating,
              max: FoxerScoreBreakdown.maxRating,
            ),
            _Part(
              label: l10n.foxerScorePartVolume,
              value: b.volume,
              max: FoxerScoreBreakdown.maxVolume,
            ),
            _Part(
              label: l10n.foxerScorePartReplies,
              value: b.responsiveness,
              max: FoxerScoreBreakdown.maxResponsiveness,
            ),
            _Part(
              label: l10n.foxerScorePartReliability,
              value: b.reliability,
              max: FoxerScoreBreakdown.maxReliability,
            ),
            _Part(
              label: l10n.foxerScorePartTrust,
              value: b.trust,
              max: FoxerScoreBreakdown.maxTrust,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _Fact(
                  label: l10n.foxerScoreStars,
                  value: score.isNew
                      ? l10n.searchNew
                      : score.starRating.toStringAsFixed(1),
                ),
                _Fact(
                  label: l10n.foxerStatBookings,
                  value: '${score.completedBookings}',
                ),
                _Fact(
                  label: l10n.foxerStatReplies,
                  value: l10n.foxerStatPercent(score.responseRatePercent),
                ),
                _Fact(
                  label: l10n.foxerStatCancellations,
                  value: l10n.foxerStatPercent(score.cancellationRatePercent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.foxerScorePrivate,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// One part of the score: its name, "38 / 45" and a bar.
class _Part extends StatelessWidget {
  const _Part({required this.label, required this.value, required this.max});

  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: AppTypography.body(size: 13)),
              const Spacer(),
              Text(
                l10n.foxerScorePart(shown, max.round()),
                style: AppTypography.body(size: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : (value / max).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(AppColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: AppTypography.display(size: 13),
          ),
          TextSpan(
            text: label,
            style: AppTypography.body(size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
