import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// "Plan your first event" in three steps, for someone with no bookings yet.
/// The caller shows it only then, so it goes away by itself after the first
/// booking. The first step ticks once they have opened an occasion.
class FirstEventChecklist extends StatelessWidget {
  const FirstEventChecklist({
    required this.pickedOccasion,
    required this.onStart,
    super.key,
  });

  /// They have already opened an occasion (step one is done).
  final bool pickedOccasion;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final done = pickedOccasion ? 1 : 0;
    final steps = [
      (l10n.homeChecklistStep1, pickedOccasion),
      (l10n.homeChecklistStep2, false),
      (l10n.homeChecklistStep3, false),
    ];

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
                child: Text(
                  l10n.homeChecklistTitle,
                  style: AppTypography.display(size: 18),
                ),
              ),
              Text(
                l10n.homeChecklistProgress(done, steps.length),
                style: AppTypography.label(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (label, isDone) in steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isDone ? AppColors.accent : AppColors.textFaint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.body(
                        color: isDone
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: pickedOccasion
                ? l10n.homeChecklistContinue
                : l10n.homeChecklistStart,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
