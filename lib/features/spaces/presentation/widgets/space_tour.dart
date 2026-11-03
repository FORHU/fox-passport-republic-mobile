import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One card of a Foxer's first-time tour.
class TourStep {
  const TourStep({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// Shows [steps] one card at a time over a dimmed screen, and completes when
/// the person finishes or skips.
Future<void> showSpaceTour(BuildContext context, List<TourStep> steps) {
  if (steps.isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: context.l10n.tourSkip,
    barrierColor: AppColors.scrim,
    pageBuilder: (_, __, ___) => _TourCard(steps: steps),
  );
}

class _TourCard extends StatefulWidget {
  const _TourCard({required this.steps});

  final List<TourStep> steps;

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = widget.steps;
    final step = steps[_index];
    final last = _index == steps.length - 1;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: AppColors.surface,
            borderRadius: AppRadius.brCard,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: AppRadius.brCard,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: AppColors.accent, size: 28),
                      const Spacer(),
                      Text(
                        l10n.tourStepOf(_index + 1, steps.length),
                        style: AppTypography.label(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(step.title, style: AppTypography.display(size: 20)),
                  const SizedBox(height: 6),
                  Text(step.body, style: AppTypography.body()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!last)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                          ),
                          child: Text(l10n.tourSkip),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: last
                            ? () => Navigator.of(context).pop()
                            : () => setState(() => _index++),
                        child: Text(last ? l10n.tourDone : l10n.tourNext),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
