import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';

/// A Foxer's Passport for one role: how far along its XP [path] they are, the
/// perks they hold and the badges they can earn in it.
///
/// The level and the XP inside it are the server's. The app only needs the
/// size of the level to draw the bar, which it takes from the same curve as
/// [PassportSummary.xpRequiredForLevel].
class FoxerPassport extends Equatable {
  const FoxerPassport({
    required this.path,
    required this.level,
    required this.currentXp,
    required this.totalXp,
    required this.perks,
    required this.badges,
  });

  /// The XP path as the API names it (`venueFoxer`, `eventFoxer`, ...).
  final String path;
  final int level;

  /// XP gained inside the current level.
  final int currentXp;
  final int totalXp;

  /// Perk keys the account holds, as the API stores them.
  final List<String> perks;

  /// Badges earned in this role or for any role, then those still locked.
  final List<PassportBadge> badges;

  /// XP the current level asks for in all.
  int get levelSpan =>
      PassportSummary.xpRequiredForLevel(level + 1) -
      PassportSummary.xpRequiredForLevel(level);

  /// 0 to 1 through the current level.
  double get progress {
    final span = levelSpan;
    if (span <= 0) return 0;
    return (currentXp / span).clamp(0, 1).toDouble();
  }

  /// XP still needed for the next level.
  int get xpToNext => math.max(0, levelSpan - currentXp);

  @override
  List<Object?> get props => [path, level, currentXp, totalXp, perks, badges];
}
