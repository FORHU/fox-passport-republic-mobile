import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What a Provider specialises in, as chips, with the one-booking-at-a-time
/// note. It takes no room for a Foxer with no specialties.
class FoxerSpecialties extends StatelessWidget {
  const FoxerSpecialties({required this.specialties, super.key});

  final List<String> specialties;

  @override
  Widget build(BuildContext context) {
    if (specialties.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.foxerSpecialtiesTitle.toUpperCase(),
              style: AppTypography.label(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in specialties)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      name,
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.foxerSpecialtiesNote,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
