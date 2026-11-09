import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/core/utils/rank_ladder.dart';

const List<String> _badgeFiles = [
  'rank-1-newcomer',
  'rank-2-wanderer',
  'rank-3-explorer',
  'rank-4-trailblazer',
  'rank-5-voyager',
  'rank-6-adventurer',
  'rank-7-pioneer',
  'rank-8-vanguard',
  'rank-9-legend',
];

/// The badge for a rank, drawn from the FoxPassport fox logo; the frame grows
/// and the keyhole opens as the rank rises. The colours are part of each
/// drawing (grey, green, cyan, magenta, lime for Legend), so nothing here
/// tints it. Made for the dark canvas.
class RankBadge extends StatelessWidget {
  /// A badge for [rank], 1 to 9 (out of range is clamped).
  const RankBadge({required this.rank, this.size = 24, this.label, super.key});

  /// The badge a [level] has earned.
  factory RankBadge.forLevel(
    int level, {
    double size = 24,
    String? label,
    Key? key,
  }) =>
      RankBadge(
        rank: rankNumberForLevel(level),
        size: size,
        label: label,
        key: key,
      );

  /// 1 (Newcomer or Rookie) to 9 (Legend).
  final int rank;

  /// The height; the drawing is 10:11, so the width follows.
  final double size;

  /// What a screen reader says, such as the rank name. The badge is skipped by
  /// screen readers when null, because the rank name is usually printed beside
  /// it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final file = _badgeFiles[rank.clamp(1, _badgeFiles.length) - 1];
    final picture = SvgPicture.asset(
      'assets/badges/$file.svg',
      height: size,
      width: size * 200 / 220,
    );
    if (label == null) return ExcludeSemantics(child: picture);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(child: picture),
    );
  }
}
