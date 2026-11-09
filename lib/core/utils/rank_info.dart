/// Facts about the nine-rank ladder that the rank-up sheet needs, copied from
/// the server (`fox-passport-republic-api/src/modules/passport/rank.service.ts`,
/// requirements/xp-and-coins.md section 4.2). The server owns the rank name it
/// sends; this only says what comes next and what reaching a rank pays.
library;

import 'package:flutter_template/core/utils/rank_ladder.dart';

/// Coins paid on reaching rank 1 to 9.
const List<int> _rankUpCoins = [0, 50, 100, 200, 300, 500, 800, 1200, 2000];

const List<String> _citizenNames = [
  'Newcomer',
  'Wanderer',
  'Explorer',
  'Trailblazer',
  'Voyager',
  'Adventurer',
  'Pioneer',
  'Vanguard',
  'Legend',
];

const List<String> _foxerNames = [
  'Rookie',
  'Regular',
  'Pro',
  'Veteran',
  'Headliner',
  'Maestro',
  'Icon',
  'Luminary',
  'Legend',
];

/// The XP attending an event pays (the seeded `attend_event` rule, 100 XP).
/// The Coins are not fixed: a booking's Coin budget can trim them.
const int attendEventXp = 100;

/// How many ranks there are.
const int rankCount = 9;

/// The Coins reaching [rank] pays (0 for rank 1 and for a number off the
/// ladder).
int rankUpCoinsFor(int rank) =>
    rank < 1 || rank > rankCount ? 0 : _rankUpCoins[rank - 1];

/// The first level of [rank]; null off the ladder.
int? minLevelOfRank(int rank) =>
    rank < 1 || rank > rankCount ? null : rankMinLevels[rank - 1];

/// The name of [rank], 1 to 9, on the citizen ladder ("Explorer"); empty off
/// the ladder. The server owns the name it sends, so use this only where it
/// has not sent one.
String citizenRankName(int rank) =>
    rank < 1 || rank > rankCount ? '' : _citizenNames[rank - 1];

/// The name of the rank after the one called [name], on the same ladder
/// (citizen or Foxer); null for the top rank or a name it does not know.
String? nextRankName(String name) {
  final wanted = name.trim().toLowerCase();
  for (final ladder in [_citizenNames, _foxerNames]) {
    final i = ladder.indexWhere((n) => n.toLowerCase() == wanted);
    if (i != -1) return i + 1 < ladder.length ? ladder[i + 1] : null;
  }
  return null;
}

/// How far a [level] is from the start of its rank to the start of the next,
/// 0 to 1; 1 at the top rank.
double rankProgress(int level) {
  final rank = rankNumberForLevel(level);
  if (rank >= rankCount) return 1;
  final start = rankMinLevels[rank - 1];
  final end = rankMinLevels[rank];
  return ((level - start) / (end - start)).clamp(0.0, 1.0);
}
