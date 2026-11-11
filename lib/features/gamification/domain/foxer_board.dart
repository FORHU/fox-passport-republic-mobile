import 'package:equatable/equatable.dart';

/// The Foxer roles the leaderboard can be filtered by.
enum LeaderboardRole {
  venue('venueFoxer'),
  event('eventFoxer'),
  gear('gearFoxer'),
  services('serviceFoxer'),
  performers('performerFoxer');

  const LeaderboardRole(this.accountRole);

  /// The account role the API takes as its `role` parameter.
  final String accountRole;

  /// The role named in the screen's route (`venue`, `event`, ...).
  static LeaderboardRole? fromRoute(String? value) {
    for (final role in values) {
      if (role.name == value) return role;
    }
    return null;
  }

  /// The role an API row names (`venueFoxer`, ...); null for anything else.
  static LeaderboardRole? fromAccountRole(String? value) {
    for (final role in values) {
      if (role.accountRole == value) return role;
    }
    return null;
  }
}

/// The Foxer board's tabs, as the API names them.
enum FoxerTab {
  topRated('top_rated'),
  mostBooked('most_booked'),
  rising('rising');

  const FoxerTab(this.api);

  /// The value of the API's `tab` parameter.
  final String api;

  static FoxerTab? fromApi(String? value) {
    for (final tab in values) {
      if (tab.api == value) return tab;
    }
    return null;
  }
}

/// One Foxer on the board. It has a rating and a review count; the number of
/// bookings behind a position is not kept, because it is not shown.
class FoxerBoardEntry extends Equatable {
  const FoxerBoardEntry({
    required this.position,
    required this.userId,
    required this.name,
    required this.role,
    required this.starRating,
    required this.reviewCount,
    this.image,
    this.city,
  });

  factory FoxerBoardEntry.fromJson(
    Map<String, dynamic> json, {
    required LeaderboardRole fallbackRole,
  }) =>
      FoxerBoardEntry(
        position: (json['position'] as num?)?.toInt() ?? 0,
        userId: '${json['userId']}',
        name: (json['name'] as String?) ?? '',
        image: json['avatarUrl'] as String?,
        city: json['city'] as String?,
        role: LeaderboardRole.fromAccountRole(json['role'] as String?) ??
            fallbackRole,
        starRating: (json['starRating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      );

  /// Fewer reviews than this and the rating is shown as "New", never a number.
  static const int minReviewsForRating = 5;

  final int position;
  final String userId;
  final String name;
  final String? image;
  final String? city;
  final LeaderboardRole role;
  final double starRating;
  final int reviewCount;

  /// A rating is only worth showing once enough people have given one.
  bool get hasRating => reviewCount >= minReviewsForRating;

  @override
  List<Object?> get props => [
        position,
        userId,
        name,
        image,
        city,
        role,
        starRating,
        reviewCount,
      ];
}

/// A board: the Foxers of a role for a tab, and the caller's own place.
class FoxerBoard extends Equatable {
  const FoxerBoard({
    required this.tab,
    required this.role,
    required this.rows,
    this.city,
    this.me,
  });

  factory FoxerBoard.fromJson(
    Map<String, dynamic> json, {
    required LeaderboardRole requestedRole,
  }) {
    final role = LeaderboardRole.fromAccountRole(json['role'] as String?) ??
        requestedRole;
    final entries = json['entries'];
    final me = json['userPosition'];
    return FoxerBoard(
      tab: FoxerTab.fromApi(json['tab'] as String?) ?? FoxerTab.topRated,
      role: role,
      city: json['city'] as String?,
      rows: [
        for (final r in (entries is List ? entries : const []))
          if (r is Map)
            FoxerBoardEntry.fromJson(
              r.cast<String, dynamic>(),
              fallbackRole: role,
            ),
      ],
      me: me is Map
          ? FoxerBoardEntry.fromJson(
              me.cast<String, dynamic>(),
              fallbackRole: role,
            )
          : null,
    );
  }

  final FoxerTab tab;
  final LeaderboardRole role;
  final String? city;
  final List<FoxerBoardEntry> rows;

  /// The caller's own place, even when it is below the rows; null if absent.
  final FoxerBoardEntry? me;

  /// The caller's place is already visible in [rows].
  bool get meIsListed => me != null && rows.any((r) => r.userId == me!.userId);

  @override
  List<Object?> get props => [tab, role, city, rows, me];
}

/// What is asked of the board: the role, the tab and, optionally, the city.
class BoardQuery extends Equatable {
  const BoardQuery(this.role, {this.tab = FoxerTab.topRated, this.city});

  final LeaderboardRole role;
  final FoxerTab tab;
  final String? city;

  @override
  List<Object?> get props => [role, tab, city];
}
