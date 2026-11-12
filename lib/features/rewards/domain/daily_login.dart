import 'package:equatable/equatable.dart';

/// Why a citizen cannot claim daily login right now, as the API names it.
enum DailyLoginBlock {
  inactive,
  emailNotVerified,
  capReached;

  static DailyLoginBlock? tryParse(Object? v) => switch (v) {
        'inactive' => inactive,
        'email_not_verified' => emailNotVerified,
        'cap_reached' => capReached,
        _ => null,
      };
}

/// Where today's daily login stands for the signed-in person. The server
/// decides everything here; the app only shows it.
class DailyLoginStatus extends Equatable {
  const DailyLoginStatus({
    required this.claimedToday,
    required this.canClaim,
    required this.amount,
    required this.streak,
    this.block,
  });

  factory DailyLoginStatus.fromJson(Map<String, dynamic> json) =>
      DailyLoginStatus(
        claimedToday: json['claimedToday'] == true,
        canClaim: json['canClaim'] == true,
        block: DailyLoginBlock.tryParse(json['reason']),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
      );

  final bool claimedToday;
  final bool canClaim;

  /// Null when nothing stops a claim (or today is already claimed).
  final DailyLoginBlock? block;

  /// What a claim pays, before the monthly limit trims it.
  final int amount;

  /// Days in a row claimed.
  final int streak;

  @override
  List<Object?> get props => [claimedToday, canClaim, block, amount, streak];
}

/// The answer to a claim: what was paid, and the status after it.
class DailyLoginClaim extends Equatable {
  const DailyLoginClaim({
    required this.claimed,
    required this.coinsAwarded,
    required this.status,
  });

  factory DailyLoginClaim.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    return DailyLoginClaim(
      claimed: json['claimed'] == true,
      coinsAwarded: (json['coinsAwarded'] as num?)?.toInt() ?? 0,
      status: DailyLoginStatus.fromJson(
        status is Map ? status.cast<String, dynamic>() : const {},
      ),
    );
  }

  /// Tokens were paid by this claim.
  final bool claimed;
  final int coinsAwarded;
  final DailyLoginStatus status;

  @override
  List<Object?> get props => [claimed, coinsAwarded, status];
}
