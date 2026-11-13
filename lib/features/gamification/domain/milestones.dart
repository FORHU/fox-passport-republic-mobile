import 'package:equatable/equatable.dart';

/// One tier of a milestone: the count it asks for and the Tokens it pays.
class MilestoneTier extends Equatable {
  const MilestoneTier({
    required this.tier,
    required this.target,
    required this.tokens,
    required this.isReached,
    this.badgeName,
  });

  factory MilestoneTier.fromJson(Map<String, dynamic> json) => MilestoneTier(
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        target: (json['target'] as num?)?.toInt() ?? 0,
        tokens: (json['tokens'] as num?)?.toInt() ?? 0,
        badgeName: _nonEmpty(json['badgeName']),
        isReached: json['isReached'] == true,
      );

  final int tier;
  final int target;
  final int tokens;
  final String? badgeName;
  final bool isReached;

  @override
  List<Object?> get props => [tier, target, tokens, badgeName, isReached];
}

/// One milestone track (booked events, attended events, cities, ...) and how
/// far the signed-in person is on it. The server counts and decides; the app
/// only shows it.
class Milestone extends Equatable {
  const Milestone({
    required this.key,
    required this.name,
    required this.counter,
    required this.isMoney,
    required this.currentCount,
    required this.currentTier,
    required this.nextTier,
    required this.progressPercentage,
    required this.isCompleted,
    required this.tiers,
    this.description,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    final tiers = [
      for (final t in (json['tiers'] as List? ?? const []))
        if (t is Map) MilestoneTier.fromJson(t.cast<String, dynamic>()),
    ]..sort((a, b) => a.tier.compareTo(b.tier));
    return Milestone(
      key: '${json['key']}',
      name: (json['name'] as String?) ?? '',
      description: _nonEmpty(json['description']),
      counter: '${json['counter'] ?? json['key']}',
      isMoney: json['unit'] == 'php',
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      currentTier: (json['currentTier'] as num?)?.toInt() ?? 0,
      nextTier: (json['nextTier'] as num?)?.toInt(),
      progressPercentage:
          ((json['progressPercentage'] as num?)?.toDouble() ?? 0).clamp(0, 100),
      isCompleted: json['isCompleted'] == true,
      tiers: tiers,
    );
  }

  final String key;
  final String name;
  final String? description;

  /// What is counted, as the API names it: `booked_events`, `attended_events`,
  /// `cities`, `venues`, `reviews` or `spend`.
  final String counter;

  /// Big Spender counts whole pesos instead of a number of things.
  final bool isMoney;
  final int currentCount;

  /// The highest tier reached; 0 before the first.
  final int currentTier;

  /// The next tier to reach; null once the last is reached.
  final int? nextTier;

  /// Progress toward the next tier, 0 to 100.
  final double progressPercentage;
  final bool isCompleted;
  final List<MilestoneTier> tiers;

  MilestoneTier? get next {
    if (nextTier == null) return null;
    for (final t in tiers) {
      if (t.tier == nextTier) return t;
    }
    return null;
  }

  /// How many more it takes to reach [next]; 0 when every tier is reached.
  int get remaining {
    final n = next;
    return n == null ? 0 : (n.target - currentCount).clamp(0, n.target);
  }

  /// What every tier of this track pays together.
  int get totalTokens => tiers.fold(0, (sum, t) => sum + t.tokens);

  @override
  List<Object?> get props => [
        key,
        name,
        description,
        counter,
        isMoney,
        currentCount,
        currentTier,
        nextTier,
        progressPercentage,
        isCompleted,
        tiers,
      ];
}

/// How long a challenge lasts before it starts over (Manila time).
enum ChallengePeriod {
  day,
  week,
  month;

  /// Reads the API's `day`, `week` or `month`; null for anything else.
  static ChallengePeriod? tryParse(Object? v) {
    for (final p in values) {
      if (p.name == v) return p;
    }
    return null;
  }
}

/// A short goal that starts over every day, week or month, such as "Make 3
/// bookings this week". The server counts and decides; the app only shows it.
class Challenge extends Equatable {
  const Challenge({
    required this.key,
    required this.name,
    required this.period,
    required this.target,
    required this.tokens,
    required this.currentCount,
    required this.isCompleted,
    this.description,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final target = (json['target'] as num?)?.toInt() ?? 0;
    final count = (json['currentCount'] as num?)?.toInt() ?? 0;
    return Challenge(
      key: '${json['key']}',
      name: (json['name'] as String?) ?? '',
      description: _nonEmpty(json['description']),
      // An unknown period is shown as the longest one rather than dropped.
      period: ChallengePeriod.tryParse(json['period']) ?? ChallengePeriod.month,
      target: target,
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      currentCount: count,
      isCompleted:
          json['isCompleted'] == true || (target > 0 && count >= target),
    );
  }

  final String key;
  final String name;
  final String? description;
  final ChallengePeriod period;
  final int target;

  /// What it pays; 0 until an amount is set, and then nothing is promised.
  final int tokens;
  final int currentCount;
  final bool isCompleted;

  /// 0 to 1.
  double get progress =>
      target <= 0 ? 0 : (currentCount / target).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
        key,
        name,
        description,
        period,
        target,
        tokens,
        currentCount,
        isCompleted,
      ];
}

/// Every milestone track and challenge for the signed-in person.
class MilestonesSummary extends Equatable {
  const MilestonesSummary(this.milestones, {this.challenges = const []});

  factory MilestonesSummary.fromJson(Map<String, dynamic> json) =>
      MilestonesSummary(
        [
          for (final m in (json['milestones'] as List? ?? const []))
            if (m is Map) Milestone.fromJson(m.cast<String, dynamic>()),
        ],
        challenges: [
          for (final c in (json['challenges'] as List? ?? const []))
            if (c is Map) Challenge.fromJson(c.cast<String, dynamic>()),
        ],
      );

  final List<Milestone> milestones;
  final List<Challenge> challenges;

  /// The track closest to paying: the one furthest along toward its next tier.
  /// Null when there are no tracks or every tier of every track is reached.
  Milestone? get closest {
    Milestone? best;
    for (final m in milestones) {
      if (m.isCompleted || m.next == null) continue;
      if (best == null || m.progressPercentage > best.progressPercentage) {
        best = m;
      }
    }
    return best;
  }

  Milestone? byKey(String key) {
    for (final m in milestones) {
      if (m.key == key) return m;
    }
    return null;
  }

  @override
  List<Object?> get props => [milestones, challenges];
}

String? _nonEmpty(Object? v) =>
    v is String && v.trim().isNotEmpty ? v.trim() : null;
