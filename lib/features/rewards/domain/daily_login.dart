import 'package:equatable/equatable.dart';

/// Why a citizen cannot claim daily login right now, as the API names it.
enum DailyLoginBlock {
  inactive,
  emailNotVerified,
  noAttendedBooking,
  capReached;

  static DailyLoginBlock? tryParse(Object? v) => switch (v) {
        'inactive' => inactive,
        'email_not_verified' => emailNotVerified,
        'no_attended_booking' => noAttendedBooking,
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
    this.nextAmount = 0,
    this.cycleDay = 1,
    this.cycle = const [],
  });

  factory DailyLoginStatus.fromJson(Map<String, dynamic> json) =>
      DailyLoginStatus(
        claimedToday: json['claimedToday'] == true,
        canClaim: json['canClaim'] == true,
        block: DailyLoginBlock.tryParse(json['reason']),
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        nextAmount: (json['nextAmount'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        cycleDay: ((json['cycleDay'] as num?)?.toInt() ?? 1).clamp(1, 7),
        cycle: [
          for (final v in (json['cycle'] as List? ?? const []))
            if (v is num) v.toInt(),
        ],
      );

  final bool claimedToday;
  final bool canClaim;

  /// Null when nothing stops a claim (or today is already claimed).
  final DailyLoginBlock? block;

  /// What today's claim pays, before the monthly limit trims it.
  final int amount;

  /// What tomorrow's claim pays; 0 when the server did not say.
  final int nextAmount;

  /// Days in a row claimed.
  final int streak;

  /// Which day of the 7-day cycle today is (1 to 7): the one being claimed,
  /// or, once it is claimed, the one that was.
  final int cycleDay;

  /// What each of the seven days pays, day 1 first; empty when the server did
  /// not say, and then there is no week to draw.
  final List<int> cycle;

  /// What coming back tomorrow pays: the server's word, else today's amount.
  int get tomorrow => nextAmount > 0 ? nextAmount : amount;

  /// What the last day of the cycle pays, or 0 without a cycle.
  int get day7Amount => cycle.length == 7 ? cycle.last : 0;

  @override
  List<Object?> get props => [
        claimedToday,
        canClaim,
        block,
        amount,
        nextAmount,
        streak,
        cycleDay,
        cycle,
      ];
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
