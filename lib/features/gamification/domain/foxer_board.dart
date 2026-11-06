import 'package:equatable/equatable.dart';

/// The Foxer roles the leaderboard can be filtered by, as the API names them.
enum LeaderboardRole {
  venue('venue'),
  event('event'),
  gear('gear'),
  services('services'),
  performers('performers');

  const LeaderboardRole(this.api);

  /// The value of the API's `role` parameter.
  final String api;

  static LeaderboardRole? fromApi(String? value) {
    for (final role in values) {
      if (role.api == value) return role;
    }
    return null;
  }
}

/// One Foxer on the board. The server sends a position and a rank, never how
/// many bookings it took.
class FoxerBoardEntry extends Equatable {
  const FoxerBoardEntry({
    required this.position,
    required this.userId,
    required this.name,
    required this.role,
    required this.rankName,
    required this.isMe,
    this.username,
    this.image,
    this.city,
  });

  factory FoxerBoardEntry.fromJson(Map<String, dynamic> json) {
    final rank = json['rank'];
    return FoxerBoardEntry(
      position: (json['position'] as num?)?.toInt() ?? 0,
      userId: '${json['userId']}',
      name: (json['name'] as String?) ?? '',
      username: json['username'] as String?,
      image: json['image'] as String?,
      city: json['city'] as String?,
      role: LeaderboardRole.fromApi(json['role'] as String?) ??
          LeaderboardRole.event,
      rankName: rank is Map ? (rank['name'] as String?) ?? '' : '',
      isMe: json['isMe'] == true,
    );
  }

  final int position;
  final String userId;
  final String name;
  final String? username;
  final String? image;
  final String? city;
  final LeaderboardRole role;

  /// The rank's name on this role's ladder ("Veteran").
  final String rankName;
  final bool isMe;

  @override
  List<Object?> get props =>
      [position, userId, name, username, image, city, role, rankName, isMe];
}

/// A board: the Foxers of a role for the month, and the caller's own place.
class FoxerBoard extends Equatable {
  const FoxerBoard({
    required this.role,
    required this.month,
    required this.rows,
    this.city,
    this.me,
  });

  factory FoxerBoard.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    final me = json['me'];
    return FoxerBoard(
      role: LeaderboardRole.fromApi(json['role'] as String?) ??
          LeaderboardRole.event,
      city: json['city'] as String?,
      month: (json['month'] as String?) ?? '',
      rows: [
        for (final r in (rows is List ? rows : const []))
          if (r is Map) FoxerBoardEntry.fromJson(r.cast<String, dynamic>()),
      ],
      me: me is Map
          ? FoxerBoardEntry.fromJson(me.cast<String, dynamic>())
          : null,
    );
  }

  final LeaderboardRole role;
  final String? city;

  /// The Manila month the board counts, as `YYYY-MM`.
  final String month;
  final List<FoxerBoardEntry> rows;

  /// The caller's own place, even when it is below the rows; null if absent.
  final FoxerBoardEntry? me;

  /// The caller's place is already visible in [rows].
  bool get meIsListed => me != null && rows.any((r) => r.userId == me!.userId);

  @override
  List<Object?> get props => [role, city, month, rows, me];
}

/// What is asked of the board: the role and, optionally, the city.
class BoardQuery extends Equatable {
  const BoardQuery(this.role, {this.city});

  final LeaderboardRole role;
  final String? city;

  @override
  List<Object?> get props => [role, city];
}
