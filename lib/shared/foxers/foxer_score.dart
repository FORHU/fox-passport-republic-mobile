import 'package:equatable/equatable.dart';

/// The five parts of the Foxer Score and the most each can add: Rating 45,
/// Volume 20, Responsiveness 15, Reliability 15, Trust 5 (they add up to 100).
class FoxerScoreBreakdown extends Equatable {
  const FoxerScoreBreakdown({
    required this.rating,
    required this.volume,
    required this.responsiveness,
    required this.reliability,
    required this.trust,
  });

  factory FoxerScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      FoxerScoreBreakdown(
        rating: _num(json['ratingScore']),
        volume: _num(json['volumeScore']),
        responsiveness: _num(json['responsivenessScore']),
        reliability: _num(json['reliabilityScore']),
        trust: _num(json['trustScore']),
      );

  static const double maxRating = 45;
  static const double maxVolume = 20;
  static const double maxResponsiveness = 15;
  static const double maxReliability = 15;
  static const double maxTrust = 5;

  final double rating;
  final double volume;
  final double responsiveness;
  final double reliability;
  final double trust;

  @override
  List<Object?> get props =>
      [rating, volume, responsiveness, reliability, trust];
}

/// The Foxer's own Foxer Score: 0 to 100, the parts behind it and the plain
/// numbers they come from. Only the Foxer sees this; guests see the star
/// rating, the facts and the labels. The server works every number out.
class FoxerScore extends Equatable {
  const FoxerScore({
    required this.score,
    required this.breakdown,
    required this.starRating,
    required this.reviewCount,
    required this.isNew,
    required this.completedBookings,
    required this.responseRatePercent,
    required this.cancellationRatePercent,
    required this.isIdentityVerified,
  });

  factory FoxerScore.fromJson(Map<String, dynamic> json) {
    final metrics = json['operationalMetrics'];
    final m = metrics is Map
        ? metrics.cast<String, dynamic>()
        : const <String, dynamic>{};
    final breakdown = json['breakdown'];
    return FoxerScore(
      score: ((json['foxerScore'] as num?)?.round() ?? 0).clamp(0, 100),
      breakdown: FoxerScoreBreakdown.fromJson(
        breakdown is Map ? breakdown.cast<String, dynamic>() : const {},
      ),
      starRating: (m['starRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (m['rawReviewCount'] as num?)?.toInt() ?? 0,
      isNew: m['isNew'] == true,
      completedBookings: (m['completedBookings'] as num?)?.toInt() ?? 0,
      responseRatePercent:
          (((m['responsivenessRate'] as num?)?.toDouble() ?? 0) * 100)
              .round()
              .clamp(0, 100),
      cancellationRatePercent:
          (((m['cancellationRate'] as num?)?.toDouble() ?? 0) * 100)
              .round()
              .clamp(0, 100),
      isIdentityVerified: m['isIdentityVerified'] == true,
    );
  }

  /// 0 to 100.
  final int score;
  final FoxerScoreBreakdown breakdown;

  /// The average of the guests' stars; shown as "New" while [isNew].
  final double starRating;
  final int reviewCount;

  /// Fewer than five reviews: no star rating is shown to guests yet.
  final bool isNew;
  final int completedBookings;
  final int responseRatePercent;
  final int cancellationRatePercent;
  final bool isIdentityVerified;

  @override
  List<Object?> get props => [
        score,
        breakdown,
        starRating,
        reviewCount,
        isNew,
        completedBookings,
        responseRatePercent,
        cancellationRatePercent,
        isIdentityVerified,
      ];
}

double _num(Object? v) => (v as num?)?.toDouble() ?? 0;
