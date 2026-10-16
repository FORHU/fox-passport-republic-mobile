import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A stamp earned by attending an event.
class PassportStamp extends Equatable {
  const PassportStamp({
    required this.label,
    required this.date,
  });

  /// Three letters for the place, e.g. `DVO`.
  final String label;
  final DateTime? date;

  @override
  List<Object?> get props => [label, date];
}

/// A badge in the catalogue, earned or not.
class PassportBadge extends Equatable {
  const PassportBadge({
    required this.id,
    required this.name,
    required this.earned,
    this.colorHex,
  });

  final String id;
  final String name;
  final bool earned;

  /// `#RRGGBB` from the catalogue, when it has one.
  final String? colorHex;

  @override
  List<Object?> get props => [id, name, earned, colorHex];
}

/// Everything the Passport screen shows.
class PassportSummary extends Equatable {
  const PassportSummary({
    required this.level,
    required this.totalXp,
    required this.nextLevelXp,
    required this.levelStartXp,
    required this.stamps,
    required this.badges,
    this.isSample = false,
  });

  /// What a new Citizen's passport looks like, for when there is no data yet.
  factory PassportSummary.sample() => PassportSummary(
        level: 1,
        totalXp: 15,
        levelStartXp: 0,
        nextLevelXp: 50,
        stamps: [
          PassportStamp(label: 'DVO', date: DateTime(2026, 10)),
          PassportStamp(label: 'BAG', date: DateTime(2026, 9)),
        ],
        badges: const [
          PassportBadge(id: 'sample-1', name: 'First night', earned: true),
          PassportBadge(id: 'sample-2', name: '', earned: false),
        ],
        isSample: true,
      );

  /// Builds the summary for a total XP.
  factory PassportSummary.fromTotalXp({
    required int totalXp,
    required List<PassportStamp> stamps,
    required List<PassportBadge> badges,
  }) {
    var level = 1;
    while (totalXp >= xpRequiredForLevel(level + 1)) {
      level++;
    }
    return PassportSummary(
      level: level,
      totalXp: totalXp,
      levelStartXp: xpRequiredForLevel(level),
      nextLevelXp: xpRequiredForLevel(level + 1),
      stamps: stamps,
      badges: badges,
    );
  }

  /// Stamps a passport page holds.
  static const int stampSlots = 8;

  /// The API's curve (`passport.service.ts`): 1000 XP for level 2, each level
  /// after that 15% more.
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    var total = 0;
    for (var i = 1; i < level; i++) {
      total += (1000 * math.pow(1.15, i - 1)).round();
    }
    return total;
  }

  final int level;
  final int totalXp;
  final int levelStartXp;
  final int nextLevelXp;
  final List<PassportStamp> stamps;
  final List<PassportBadge> badges;
  final bool isSample;

  /// 0 to 1 through the current level.
  double get progress {
    final span = nextLevelXp - levelStartXp;
    if (span <= 0) return 0;
    return ((totalXp - levelStartXp) / span).clamp(0, 1).toDouble();
  }

  @override
  List<Object?> get props => [
        level,
        totalXp,
        levelStartXp,
        nextLevelXp,
        stamps,
        badges,
        isSample,
      ];
}
