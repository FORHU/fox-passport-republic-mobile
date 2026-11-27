import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/venues/coverage_area.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Where a venue is available, picked from six areas, one at a time
/// (mobile#498). It replaces the radius a venue used to draw on the map.
class CoverageAreaChoice extends StatelessWidget {
  const CoverageAreaChoice({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The chosen area's code, or null when none is chosen yet.
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.studioCoverage, style: AppTypography.label()),
        const SizedBox(height: 8),
        for (final code in venueCoverageAreas) ...[
          _Option(
            key: Key('coverage-$code'),
            title: coverageAreaLabel(l10n, code),
            hint: coverageAreaHint(l10n, code),
            selected: value == code,
            onTap: () => onChanged(code),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentTintBg : AppColors.clear,
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: selected
                    ? AppColors.accentTintBorder
                    : AppColors.borderStrong,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body(weight: FontWeight.w600),
                      ),
                      Text(
                        hint,
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
          ),
        ),
      );
}
