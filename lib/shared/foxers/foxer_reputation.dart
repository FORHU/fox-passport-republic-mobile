import 'package:equatable/equatable.dart';

/// Where a Foxer stands on the Top rated board for their role in their city,
/// such as "#3 Venues in Manila".
class FoxerPlace extends Equatable {
  const FoxerPlace({required this.position, required this.role, this.city});

  /// Null unless the reply names a position of 1 or more.
  static FoxerPlace? tryParse(Object? json) {
    if (json is! Map) return null;
    final position = (json['position'] as num?)?.toInt();
    final role = json['role'];
    if (position == null || position < 1 || role is! String) return null;
    final city = json['city'];
    return FoxerPlace(
      position: position,
      role: role,
      city: city is String && city.trim().isNotEmpty ? city.trim() : null,
    );
  }

  final int position;

  /// The account role the board is for, as the API names it (`venueFoxer`).
  final String role;
  final String? city;

  @override
  List<Object?> get props => [position, role, city];
}

/// What a citizen sees when choosing a Foxer, beyond the stars: how many
/// bookings they have completed, how often they answer in time, how often they
/// cancel, and the labels they have earned. The server works all of it out; the
/// 0 to 100 Foxer Score behind the labels is never sent to citizens.
class FoxerReputation extends Equatable {
  const FoxerReputation({
    required this.starRating,
    required this.reviewCount,
    required this.isNew,
    required this.completedBookings,
    required this.responseRatePercent,
    required this.cancellationRatePercent,
    required this.isIdentityVerified,
    required this.labels,
    this.place,
  });

  factory FoxerReputation.fromJson(Map<String, dynamic> json) =>
      FoxerReputation(
        starRating: (json['starRating'] as num?)?.toDouble(),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        isNew: json['isNew'] == true,
        completedBookings: (json['completedBookings'] as num?)?.toInt() ?? 0,
        responseRatePercent:
            ((json['responseRatePercent'] as num?)?.toInt() ?? 0).clamp(0, 100),
        cancellationRatePercent:
            ((json['cancellationRatePercent'] as num?)?.toInt() ?? 0)
                .clamp(0, 100),
        isIdentityVerified: json['isIdentityVerified'] == true,
        labels: [
          for (final l in (json['labels'] as List? ?? const []))
            if (l is String && l.trim().isNotEmpty) l.trim(),
        ],
        place: FoxerPlace.tryParse(json['leaderboard']),
      );

  /// Null while the Foxer is new (fewer than five reviews): show "New".
  final double? starRating;
  final int reviewCount;
  final bool isNew;
  final int completedBookings;
  final int responseRatePercent;
  final int cancellationRatePercent;
  final bool isIdentityVerified;

  /// "Top rated", "Fast responder", "Reliable" or "Rising", as the server
  /// named them.
  final List<String> labels;

  /// Their place on the leaderboard; null when they are not on one.
  final FoxerPlace? place;

  /// Nothing to show yet: no bookings and no labels.
  bool get isEmpty => completedBookings == 0 && labels.isEmpty && place == null;

  @override
  List<Object?> get props => [
        starRating,
        reviewCount,
        isNew,
        completedBookings,
        responseRatePercent,
        cancellationRatePercent,
        isIdentityVerified,
        labels,
        place,
      ];
}
