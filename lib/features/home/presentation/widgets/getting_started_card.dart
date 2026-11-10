import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One line of the Getting started card.
class GettingStartedStep {
  const GettingStartedStep({
    required this.label,
    required this.done,
    required this.onTap,
    this.reward,
  });

  final String label;
  final bool done;
  final VoidCallback onTap;

  /// What finishing it pays, such as "+30 XP · 10 Coins"; nothing when it pays
  /// no fixed amount.
  final String? reward;
}

/// The checklist on Home that walks a new citizen through the tour, a complete
/// profile, an ID check and a first booking. The server decides which of the
/// first three are done; the caller passes them in and shows the card only
/// while something is left, so it goes away by itself.
///
/// It starts as one short card (progress bar and the next step) so it does not
/// push the page's main actions down; tapping it opens the whole list.
class GettingStartedCard extends StatefulWidget {
  const GettingStartedCard({
    required this.steps,
    this.initiallyExpanded = false,
    super.key,
  });

  final List<GettingStartedStep> steps;
  final bool initiallyExpanded;

  @override
  State<GettingStartedCard> createState() => _GettingStartedCardState();
}

class _GettingStartedCardState extends State<GettingStartedCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = widget.steps;
    final done = steps.where((s) => s.done).length;
    final next = steps.where((s) => !s.done).firstOrNull;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: AppRadius.brMd,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.gettingStartedTitle,
                          style: AppTypography.display(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.homeChecklistProgress(done, steps.length),
                          textAlign: TextAlign.end,
                          style: AppTypography.label(),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: AppRadius.brPill,
                    child: LinearProgressIndicator(
                      value: steps.isEmpty ? 0 : done / steps.length,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceRaised,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                  if (!_expanded && next != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.gettingStartedNext(next.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [for (final step in steps) _StepRow(step: step)],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final GettingStartedStep step;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brMd,
      // A finished step has nothing left to do.
      onTap: step.done ? null : step.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(
              step.done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: step.done ? AppColors.accent : AppColors.textFaint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.label,
                    style: AppTypography.body(
                      color: step.done
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (step.reward != null && !step.done)
                    Text(
                      step.reward!,
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (!step.done)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
