/// The nine-rank ladder as the server defines it
/// (`fox-passport-republic-api/src/modules/passport/rank.service.ts`,
/// requirements/xp-and-coins.md section 4.2). Citizens and Foxers share the
/// thresholds, so a rank number comes from the level alone. The server owns
/// the rank name; this only picks the badge that goes with a level.
const List<int> rankMinLevels = [1, 3, 5, 10, 15, 20, 30, 40, 50];

/// The rank number, 1 to 9, a [level] has reached. A level below 1 counts as 1
/// and a level past 50 stays at 9, the top rank.
int rankNumberForLevel(int level) {
  var rank = 1;
  for (var i = 0; i < rankMinLevels.length; i++) {
    if (level >= rankMinLevels[i]) rank = i + 1;
  }
  return rank;
}
