import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A filter pill: white when chosen, dark with a border when not. At least
/// 40 px tall, so it is a comfortable thumb target.
class PillChip extends StatelessWidget {
  const PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: AppRadius.brPill,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.textPrimary : AppColors.surface,
              borderRadius: AppRadius.brPill,
              border: Border.all(
                color: selected ? AppColors.textPrimary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.display(
                size: 14,
                color: selected ? AppColors.canvas : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
