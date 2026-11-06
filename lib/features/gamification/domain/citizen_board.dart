import 'package:equatable/equatable.dart';

/// Which board the Leaderboard screen shows.
enum LeaderboardSide {
  citizens('citizens'),
  foxers('foxers');

  const LeaderboardSide(this.api);

  /// The value used in the screen's route.
  final String api;

  static LeaderboardSide? fromApi(String? value) {
    for (final side in values) {
      if (side.api == value) return side;
    }
    return null;
  }
}

/// The citizen board's tabs, as the API names them.
enum CitizenTab {
  month('this_month'),
  all('all_time'),
  city('my_city');

  const CitizenTab(this.api);

  /// The value of the API's `tab` parameter.
  final String api;

  static CitizenTab? fromApi(String? value) {
    for (final tab in values) {
      if (tab.api == value) return tab;
    }
    return null;
  }
}

/// One citizen on the board. The server sends a position, a rank and a level,
/// never the XP behind them.
class CitizenBoardEntry extends Equatable {
  const CitizenBoardEntry({
    required this.position,
    required this.userId,
    required this.name,
    required this.rankName,
    required this.level,
    this.image,
    this.city,
  });

  factory CitizenBoardEntry.fromJson(Map<String, dynamic> json) =>
      CitizenBoardEntry(
        position: (json['position'] as num?)?.toInt() ?? 0,
        userId: '${json['userId']}',
        name: (json['name'] as String?) ?? '',
        image: json['avatarUrl'] as String?,
        city: json['city'] as String?,
        rankName: (json['rankTitle'] as String?) ?? '',
        level: (json['level'] as num?)?.toInt() ?? 1,
      );

  final int position;
  final String userId;
  final String name;
  final String? image;
  final String? city;

  /// The rank's name on the citizen ladder ("Explorer").
  final String rankName;
  final int level;

  @override
  List<Object?> get props =>
      [position, userId, name, image, city, rankName, level];
}

/// A citizen board for one tab, and the caller's own place on it.
class CitizenBoard extends Equatable {
  const CitizenBoard({
    required this.tab,
    required this.rows,
    this.season,
    this.me,
  });

  factory CitizenBoard.fromJson(Map<String, dynamic> json) {
    final entries = json['entries'];
    final me = json['userPosition'];
    return CitizenBoard(
      tab: CitizenTab.fromApi(json['tab'] as String?) ?? CitizenTab.month,
      season: json['season'] as String?,
      rows: [
        for (final r in (entries is List ? entries : const []))
          if (r is Map) CitizenBoardEntry.fromJson(r.cast<String, dynamic>()),
      ],
      me: me is Map
          ? CitizenBoardEntry.fromJson(me.cast<String, dynamic>())
          : null,
    );
  }

  final CitizenTab tab;

  /// The month counted, as `YYYY-MM`.
  final String? season;
  final List<CitizenBoardEntry> rows;

  /// The caller's own place, even when it is below the rows; null if absent.
  final CitizenBoardEntry? me;

  /// The caller's place is already visible in [rows].
  bool get meIsListed => me != null && rows.any((r) => r.userId == me!.userId);

  @override
  List<Object?> get props => [tab, season, rows, me];
}

/// What is asked of the citizen board: the tab and, for My city, the city.
class CitizenQuery extends Equatable {
  const CitizenQuery(this.tab, {this.city});

  final CitizenTab tab;
  final String? city;

  @override
  List<Object?> get props => [tab, city];
}
