import 'package:equatable/equatable.dart';
import 'package:flutter_template/core/utils/rank_ladder.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';

/// A reward rule's name as snake_case, whichever way the server spelled it
/// (`attend_event`, `attendEvent`).
/// The Coins a grant has paid so far: none while they are held.
int _paidCoins(WalletEntry e) => e.isPending ? 0 : e.coinsDelta;

String snakeAction(String? action) => (action ?? '')
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toLowerCase()
    .trim();

/// What the person earned since they last looked: XP and Coins added up, and
/// what it was mostly for.
class RewardMoment extends Equatable {
  const RewardMoment({
    required this.xp,
    required this.coins,
    required this.action,
    this.bookingId,
  });

  final int xp;
  final int coins;

  /// The booking the biggest grant was for, when it was for one.
  final String? bookingId;

  /// The reward rule behind the biggest grant, as snake_case, such as
  /// `attend_event`.
  final String? action;

  @override
  List<Object?> get props => [xp, coins, action, bookingId];
}

/// A rank the person has reached since they last looked.
class RankUpMoment extends Equatable {
  const RankUpMoment({required this.fromRank, required this.toRank});

  /// The rank they had, and the one they have now, 1 to 9.
  final int fromRank;
  final int toRank;

  @override
  List<Object?> get props => [fromRank, toRank];
}

/// What to show now, and what to remember so it is shown only once.
class RewardMoments extends Equatable {
  const RewardMoments({
    required this.seenAt,
    required this.seenRank,
    this.reward,
    this.rankUp,
  });

  final RewardMoment? reward;
  final RankUpMoment? rankUp;

  /// The newest grant the person has now seen (or been spared), to remember.
  final DateTime? seenAt;

  /// The rank they have now, to remember.
  final int seenRank;

  bool get isEmpty => reward == null && rankUp == null;

  @override
  List<Object?> get props => [reward, rankUp, seenAt, seenRank];
}

/// Works out what is new in [history] since [seenAt], and whether [level]
/// is a higher rank than [seenRank].
///
/// With no [seenAt] this is the first look on this phone: nothing is shown,
/// so an old account is not greeted with its whole history, and what is there
/// now is remembered. The rank-up Coins are left out of the reward, because
/// the rank-up sheet is where they are announced.
RewardMoments detectRewardMoments({
  required List<WalletEntry> history,
  required int level,
  required DateTime? seenAt,
  required int? seenRank,
}) {
  final rank = rankNumberForLevel(level);
  final grants = [
    for (final e in history)
      if (e.isGrant) e,
  ];
  DateTime? newest;
  for (final g in grants) {
    if (newest == null || g.createdAt.isAfter(newest)) newest = g.createdAt;
  }

  if (seenAt == null || seenRank == null) {
    return RewardMoments(seenAt: newest, seenRank: rank);
  }

  final fresh = [
    for (final g in grants)
      if (g.createdAt.isAfter(seenAt) &&
          snakeAction(g.action) != 'rank_up' &&
          (g.xp > 0 || _paidCoins(g) > 0))
        g,
  ];
  RewardMoment? reward;
  if (fresh.isNotEmpty) {
    var biggest = fresh.first;
    var xp = 0;
    var coins = 0;
    for (final g in fresh) {
      xp += g.xp;
      coins += _paidCoins(g);
      if (g.xp + _paidCoins(g) > biggest.xp + _paidCoins(biggest)) biggest = g;
    }
    reward = RewardMoment(
      xp: xp,
      coins: coins,
      action: snakeAction(biggest.action),
      bookingId: biggest.refType == 'booking' ? biggest.refId : null,
    );
  }

  return RewardMoments(
    reward: reward,
    rankUp:
        rank > seenRank ? RankUpMoment(fromRank: seenRank, toRank: rank) : null,
    seenAt: newest != null && newest.isAfter(seenAt) ? newest : seenAt,
    seenRank: rank,
  );
}
