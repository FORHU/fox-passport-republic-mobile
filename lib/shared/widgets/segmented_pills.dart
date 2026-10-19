import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One choice in [SegmentedPills].
class SegmentOption<T> {
  const SegmentOption(this.value, this.label);

  final T value;
  final String label;
}

/// A full-width pill switch: "Upcoming | Past", "Events | Venues | …".
///
/// The chosen segment is raised; the rest are muted text. Each segment is at
/// least 40 px tall, so it is a comfortable thumb target.
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 4 all round; 2 above and below sit inside each pill's tap area.
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option.value == value,
                label: option.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option.value),
                  // The pill is 40 tall; the area that answers a tap is 44.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option.value == value
                            ? AppColors.surfaceRaised
                            : Colors.transparent,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          size: 14,
                          color: option.value == value
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
