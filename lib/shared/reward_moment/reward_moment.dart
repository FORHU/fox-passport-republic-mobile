import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';

/// The Tokens a grant has paid so far: none while they are held.
int _paidCoins(WalletEntry e) => e.isPending ? 0 : e.coinsDelta;

/// A reward rule's name as snake_case, whichever way the server spelled it
/// (`attend_event`, `attendEvent`).
String snakeAction(String? action) => (action ?? '')
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toLowerCase()
    .trim();

/// What the person earned since they last looked: Tokens added up, and what it
/// was mostly for.
class RewardMoment extends Equatable {
  const RewardMoment({
    required this.coins,
    required this.action,
    this.bookingId,
  });

  /// The Tokens (the data and API still say `coins`).
  final int coins;

  /// The booking the biggest grant was for, when it was for one.
  final String? bookingId;

  /// The reward rule behind the biggest grant, as snake_case, such as
  /// `attend_event`.
  final String? action;

  @override
  List<Object?> get props => [coins, action, bookingId];
}

/// What to show now, and what to remember so it is shown only once.
class RewardMoments extends Equatable {
  const RewardMoments({required this.seenAt, this.reward});

  final RewardMoment? reward;

  /// The newest grant the person has now seen (or been spared), to remember.
  final DateTime? seenAt;

  bool get isEmpty => reward == null;

  @override
  List<Object?> get props => [reward, seenAt];
}

/// Works out what is new in [history] since [seenAt].
///
/// With no [seenAt] this is the first look on this phone: nothing is shown,
/// so an old account is not greeted with its whole history, and what is there
/// now is remembered.
RewardMoments detectRewardMoments({
  required List<WalletEntry> history,
  required DateTime? seenAt,
}) {
  final grants = [
    for (final e in history)
      if (e.isGrant) e,
  ];
  DateTime? newest;
  for (final g in grants) {
    if (newest == null || g.createdAt.isAfter(newest)) newest = g.createdAt;
  }

  if (seenAt == null) return RewardMoments(seenAt: newest);

  final fresh = [
    for (final g in grants)
      if (g.createdAt.isAfter(seenAt) && _paidCoins(g) > 0) g,
  ];
  RewardMoment? reward;
  if (fresh.isNotEmpty) {
    var biggest = fresh.first;
    var coins = 0;
    for (final g in fresh) {
      coins += _paidCoins(g);
      if (_paidCoins(g) > _paidCoins(biggest)) biggest = g;
    }
    reward = RewardMoment(
      coins: coins,
      action: snakeAction(biggest.action),
      bookingId: biggest.refType == 'booking' ? biggest.refId : null,
    );
  }

  return RewardMoments(
    reward: reward,
    seenAt: newest != null && newest.isAfter(seenAt) ? newest : seenAt,
  );
}
