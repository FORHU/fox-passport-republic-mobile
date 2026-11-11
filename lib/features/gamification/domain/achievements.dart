import 'package:equatable/equatable.dart';

/// One tier (I, II or III) of an achievement: the count it needs and what
/// reaching it pays.
class AchievementTier extends Equatable {
  const AchievementTier({
    required this.tier,
    required this.target,
    required this.coins,
    required this.isUnlocked,
    this.badgeName,
  });

  factory AchievementTier.fromJson(Map<String, dynamic> json) =>
      AchievementTier(
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        target: (json['target'] as num?)?.toInt() ?? 0,
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        badgeName: _nonEmpty(json['badgeName']),
        isUnlocked: json['isUnlocked'] == true,
      );

  /// 1, 2 or 3.
  final int tier;
  final int target;
  final int coins;
  final String? badgeName;
  final bool isUnlocked;

  @override
  List<Object?> get props => [tier, target, coins, badgeName, isUnlocked];
}

/// Where an achievement stands.
enum AchievementState { locked, inProgress, done }

/// One achievement and how far the signed-in person is on it. The server
/// counts and decides; the app only shows it.
class Achievement extends Equatable {
  const Achievement({
    required this.key,
    required this.name,
    required this.description,
    required this.isFoxer,
    required this.currentCount,
    required this.currentTier,
    required this.nextTier,
    required this.targetCount,
    required this.progressPercentage,
    required this.isCompleted,
    required this.tiers,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        key: '${json['key']}',
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        isFoxer: json['category'] == 'foxer',
        currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
        currentTier: (json['currentTier'] as num?)?.toInt() ?? 0,
        nextTier: (json['nextTier'] as num?)?.toInt(),
        targetCount: (json['targetCount'] as num?)?.toInt() ?? 0,
        progressPercentage:
            ((json['progressPercentage'] as num?)?.toDouble() ?? 0)
                .clamp(0, 100),
        isCompleted: json['isCompleted'] == true,
        tiers: [
          for (final t in (json['tiers'] as List? ?? const []))
            if (t is Map) AchievementTier.fromJson(t.cast<String, dynamic>()),
        ],
      );

  final String key;
  final String name;
  final String description;
  final bool isFoxer;

  /// What has been counted so far, such as events attended.
  final int currentCount;

  /// The highest tier reached, 0 to 3.
  final int currentTier;

  /// The tier being worked towards; null once all three are done.
  final int? nextTier;

  /// The count the next tier needs.
  final int targetCount;

  /// Progress towards the next tier, 0 to 100.
  final double progressPercentage;
  final bool isCompleted;
  final List<AchievementTier> tiers;

  AchievementState get state {
    if (isCompleted) return AchievementState.done;
    if (currentTier > 0 || currentCount > 0) return AchievementState.inProgress;
    return AchievementState.locked;
  }

  /// The tier being worked towards, with what it pays; null when done.
  AchievementTier? get next {
    final wanted = nextTier;
    if (wanted == null) return null;
    for (final t in tiers) {
      if (t.tier == wanted) return t;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        key,
        name,
        description,
        isFoxer,
        currentCount,
        currentTier,
        nextTier,
        targetCount,
        progressPercentage,
        isCompleted,
        tiers,
      ];
}

/// Every achievement for the signed-in person.
class AchievementsSummary extends Equatable {
  const AchievementsSummary({
    required this.citizen,
    required this.foxer,
    required this.earnedTiers,
  });

  factory AchievementsSummary.fromJson(Map<String, dynamic> json) {
    List<Achievement> read(Object? list) => [
          for (final a in (list as List? ?? const []))
            if (a is Map) Achievement.fromJson(a.cast<String, dynamic>()),
        ];
    return AchievementsSummary(
      citizen: read(json['citizenAchievements']),
      foxer: read(json['foxerAchievements']),
      earnedTiers: (json['totalUnlockedTiers'] as num?)?.toInt() ?? 0,
    );
  }

  final List<Achievement> citizen;
  final List<Achievement> foxer;

  /// Tiers earned across all achievements, as the server counted them.
  final int earnedTiers;

  /// The achievements to show: the Foxer ones only when [withFoxer].
  List<Achievement> visible({required bool withFoxer}) =>
      [...citizen, if (withFoxer) ...foxer];

  /// Tiers there are to earn across [visible].
  int totalTiers({required bool withFoxer}) =>
      visible(withFoxer: withFoxer).fold(0, (sum, a) => sum + a.tiers.length);

  /// Tiers earned across [visible]. The server's own count covers Foxer
  /// achievements too, so with them hidden it is counted here.
  int earned({required bool withFoxer}) => withFoxer
      ? earnedTiers
      : citizen.fold(0, (sum, a) => sum + a.currentTier);

  @override
  List<Object?> get props => [citizen, foxer, earnedTiers];
}

String? _nonEmpty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;
