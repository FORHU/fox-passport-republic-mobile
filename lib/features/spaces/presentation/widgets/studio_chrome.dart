import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

// The look the venue studio and the event studio share: a header that says
// where you are, cards that group the fields, and a bar of actions at the
// bottom.

/// "STEP 2 OF 5", the step's name large, and a bar of segments, one for each
/// step. The ones up to the current step are lit; tapping one goes there.
class StudioHeader extends StatelessWidget {
  const StudioHeader({
    required this.current,
    required this.total,
    required this.title,
    required this.onSelect,
    super.key,
  });

  /// Zero-based.
  final int current;
  final int total;
  final String title;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.studioStepOf(current + 1, total),
            style: AppTypography.label(color: AppColors.accent),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTypography.display(size: 26)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    key: ValueKey('studio-step-$i'),
                    button: true,
                    selected: i == current,
                    label: '${i + 1}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      // 4 dp to look at, 20 to tap.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= current
                                ? AppColors.accent
                                : AppColors.borderStrong,
                            borderRadius: AppRadius.brPill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A group of related fields on a surface of its own, with an optional title
/// and a line saying what it is for.
class StudioCard extends StatelessWidget {
  const StudioCard({
    required this.child,
    this.title,
    this.hint,
    this.tinted = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? hint;

  /// Lime-tinted, for the one figure the card exists to show.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? AppColors.accentTintBg : AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: tinted ? AppColors.accentTintBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) Text(title!, style: AppTypography.display()),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: AppTypography.body(size: 13, color: AppColors.textMuted),
            ),
          ],
          if (title != null || hint != null) const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// The bar at the bottom: a hairline above it, and the actions inside.
class StudioBar extends StatelessWidget {
  const StudioBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

/// Back as a square button beside the main action.
class StudioBackButton extends StatelessWidget {
  const StudioBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.square(52),
          padding: EdgeInsets.zero,
        ),
        child: Tooltip(
          message: context.l10n.studioBack,
          child: const Icon(Icons.arrow_back_rounded),
        ),
      ),
    );
  }
}
