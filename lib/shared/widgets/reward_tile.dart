import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// One tile of the citizen Passport's rewards grid: an icon, a title, and an
/// optional lime hint under it. Tapping it opens [route].
class RewardTile extends StatelessWidget {
  const RewardTile({
    required this.icon,
    required this.title,
    required this.route,
    this.hint,
    super.key,
  });

  final IconData icon;
  final String title;
  final String route;

  /// A short line under the title, such as the closest milestone.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: AppColors.textPrimary),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 14),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays reward tiles out two by two, each pair as tall as its taller tile, so
/// a tile with a hint doesn't leave its neighbour short. An odd last tile
/// takes half the width.
class RewardGrid extends StatelessWidget {
  const RewardGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    Widget pair(Widget a, Widget? b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b ?? const SizedBox.shrink()),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            pair(
              children[i],
              i + 1 < children.length ? children[i + 1] : null,
            ),
          ],
        ],
      ),
    );
  }
}
