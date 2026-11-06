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
  month('month'),
  all('all'),
  city('city');

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
    required this.isMe,
    this.username,
    this.image,
    this.city,
  });

  factory CitizenBoardEntry.fromJson(Map<String, dynamic> json) {
    final rank = json['rank'];
    return CitizenBoardEntry(
      position: (json['position'] as num?)?.toInt() ?? 0,
      userId: '${json['userId']}',
      name: (json['name'] as String?) ?? '',
      username: json['username'] as String?,
      image: json['image'] as String?,
      city: json['city'] as String?,
      rankName: rank is Map ? (rank['name'] as String?) ?? '' : '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      isMe: json['isMe'] == true,
    );
  }

  final int position;
  final String userId;
  final String name;
  final String? username;
  final String? image;
  final String? city;

  /// The rank's name on the citizen ladder ("Explorer").
  final String rankName;
  final int level;
  final bool isMe;

  @override
  List<Object?> get props => [
        position,
        userId,
        name,
        username,
        image,
        city,
        rankName,
        level,
        isMe,
      ];
}

/// A citizen board for one tab, and the caller's own place on it.
class CitizenBoard extends Equatable {
  const CitizenBoard({
    required this.tab,
    required this.rows,
    this.city,
    this.month,
    this.me,
  });

  factory CitizenBoard.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    final me = json['me'];
    return CitizenBoard(
      tab: CitizenTab.fromApi(json['tab'] as String?) ?? CitizenTab.month,
      city: json['city'] as String?,
      month: json['month'] as String?,
      rows: [
        for (final r in (rows is List ? rows : const []))
          if (r is Map) CitizenBoardEntry.fromJson(r.cast<String, dynamic>()),
      ],
      me: me is Map
          ? CitizenBoardEntry.fromJson(me.cast<String, dynamic>())
          : null,
    );
  }

  final CitizenTab tab;

  /// The caller's own city on the city tab; null elsewhere, or when they have
  /// none set.
  final String? city;

  /// The Manila month counted, as `YYYY-MM`; null for all time.
  final String? month;
  final List<CitizenBoardEntry> rows;

  /// The caller's own place, even when it is below the rows; null if absent.
  final CitizenBoardEntry? me;

  /// The caller's place is already visible in [rows].
  bool get meIsListed => me != null && rows.any((r) => r.userId == me!.userId);

  @override
  List<Object?> get props => [tab, city, month, rows, me];
}
