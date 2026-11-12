import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Fewer reviews than this and a Foxer is "New": no number is shown.
const int minReviewsForPaws = 5;

/// Five paws filled to [paws] (0 to 5, partial fills allowed: 4.3 fills the
/// fifth paw by 30%). Decorative: the number beside it carries the meaning.
class PawsRow extends StatelessWidget {
  const PawsRow({required this.paws, this.size = 16, super.key});

  final double paws;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = paws.clamp(0, 5).toDouble();
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            _Paw(fill: (value - i).clamp(0, 1).toDouble(), size: size),
        ],
      ),
    );
  }
}

class _Paw extends StatelessWidget {
  const _Paw({required this.fill, required this.size});

  final double fill;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(Icons.pets, size: size, color: AppColors.border),
        ClipRect(
          clipper: _FillClipper(fill),
          child: Icon(Icons.pets, size: size, color: AppColors.warning),
        ),
      ],
    );
  }
}

class _FillClipper extends CustomClipper<Rect> {
  const _FillClipper(this.fill);

  final double fill;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_FillClipper old) => old.fill != fill;
}

/// A Foxer's Paws as one line: a paw, the number and the review count
/// ("4.8 · 32"), or "New" while there are too few reviews.
class PawsLabel extends StatelessWidget {
  const PawsLabel({
    required this.paws,
    required this.reviewCount,
    super.key,
  });

  /// The API's Paws; null means too few reviews.
  final double? paws;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = paws;
    if (value == null || reviewCount < minReviewsForPaws) {
      return Text(
        l10n.pawsNew,
        style: AppTypography.body(size: 12, color: AppColors.textMuted),
      );
    }
    return Semantics(
      label: l10n.pawsSemantics(value.toStringAsFixed(1), reviewCount),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, size: 14, color: AppColors.warning),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${value.toStringAsFixed(1)} · $reviewCount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
