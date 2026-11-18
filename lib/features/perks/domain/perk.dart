import 'package:equatable/equatable.dart';

/// A perk on offer: something real (a drink, a starter, a +1) bought with
/// Tokens, offered by a venue or an event host.
class Perk extends Equatable {
  const Perk({
    required this.id,
    required this.issuerType,
    required this.title,
    required this.tokenCost,
    this.description,
    this.remaining,
    this.validDays = 30,
    this.tokensShort = 0,
  });

  factory Perk.fromJson(Map<String, dynamic> json) => Perk(
        id: '${json['id']}',
        issuerType: '${json['issuerType'] ?? 'venue'}',
        title: '${json['title'] ?? ''}',
        description: json['description'] as String?,
        tokenCost: (json['tokenCost'] as num?)?.toInt() ?? 0,
        remaining: (json['remaining'] as num?)?.toInt(),
        validDays: (json['validDays'] as num?)?.toInt() ?? 30,
        tokensShort: (json['tokensShort'] as num?)?.toInt() ?? 0,
      );

  final String id;

  /// `venue` or `host` (FoxPassport's own perks are not listed yet).
  final String issuerType;
  final String title;
  final String? description;
  final int tokenCost;

  /// How many are left; null when there is no limit.
  final int? remaining;
  final int validDays;

  /// How many Tokens short the person is; 0 when they can afford it.
  final int tokensShort;

  bool get isHost => issuerType == 'host';
  bool get canAfford => tokensShort == 0;

  @override
  List<Object?> get props => [
        id,
        issuerType,
        title,
        description,
        tokenCost,
        remaining,
        validDays,
        tokensShort,
      ];
}

/// The perks on offer with what the person can spend and what is held back.
class PerkListing extends Equatable {
  const PerkListing({
    required this.balance,
    required this.held,
    required this.perks,
  });

  factory PerkListing.fromJson(Map<String, dynamic> json) => PerkListing(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        held: (json['held'] as num?)?.toInt() ?? 0,
        perks: [
          for (final p in (json['perks'] as List?) ?? const [])
            if (p is Map) Perk.fromJson(p.cast<String, dynamic>()),
        ],
      );

  final int balance;
  final int held;
  final List<Perk> perks;

  @override
  List<Object?> get props => [balance, held, perks];
}

/// A booking a perk can be used on.
class PerkBooking extends Equatable {
  const PerkBooking({required this.id, required this.name, this.startAt});

  factory PerkBooking.fromJson(Map<String, dynamic> json) => PerkBooking(
        id: '${json['id']}',
        name: '${json['name'] ?? ''}',
        startAt: DateTime.tryParse('${json['startAt']}')?.toLocal(),
      );

  final String id;
  final String name;
  final DateTime? startAt;

  @override
  List<Object?> get props => [id, name, startAt];
}

/// One perk and the bookings it could be used on.
class PerkDetail extends Equatable {
  const PerkDetail({
    required this.balance,
    required this.perk,
    required this.bookings,
  });

  factory PerkDetail.fromJson(Map<String, dynamic> json) => PerkDetail(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        perk: Perk.fromJson((json['perk'] as Map).cast<String, dynamic>()),
        bookings: [
          for (final b in (json['bookings'] as List?) ?? const [])
            if (b is Map) PerkBooking.fromJson(b.cast<String, dynamic>()),
        ],
      );

  final int balance;
  final Perk perk;
  final List<PerkBooking> bookings;

  @override
  List<Object?> get props => [balance, perk, bookings];
}

/// What redeeming gave back.
class PerkRedeemed extends Equatable {
  const PerkRedeemed({
    required this.redemptionId,
    required this.code,
    required this.tokensSpent,
    required this.remainingCoins,
    this.expiresAt,
  });

  factory PerkRedeemed.fromJson(Map<String, dynamic> json) => PerkRedeemed(
        redemptionId: '${json['redemptionId']}',
        code: '${json['code']}',
        tokensSpent: (json['tokensSpent'] as num?)?.toInt() ?? 0,
        remainingCoins: (json['remainingCoins'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toLocal(),
      );

  final String redemptionId;
  final String code;
  final int tokensSpent;
  final int remainingCoins;
  final DateTime? expiresAt;

  @override
  List<Object?> get props =>
      [redemptionId, code, tokensSpent, remainingCoins, expiresAt];
}

enum MyPerkState { ready, used, expired }

/// One of the person's perks: ready, used, or expired (Tokens returned).
class MyPerk extends Equatable {
  const MyPerk({
    required this.id,
    required this.title,
    required this.tokensSpent,
    required this.state,
    this.expiresAt,
    this.usedAt,
  });

  factory MyPerk.fromJson(Map<String, dynamic> json) {
    final status = '${json['status']}';
    final expired = json['expired'] == true;
    return MyPerk(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      tokensSpent: (json['tokensSpent'] as num?)?.toInt() ?? 0,
      // `returned`: expired unused or booking cancelled; Tokens came back.
      state: status == 'used'
          ? MyPerkState.used
          : (status == 'returned' || expired)
              ? MyPerkState.expired
              : MyPerkState.ready,
      expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toLocal(),
      usedAt: DateTime.tryParse('${json['usedAt']}')?.toLocal(),
    );
  }

  final String id;
  final String title;
  final int tokensSpent;
  final MyPerkState state;
  final DateTime? expiresAt;
  final DateTime? usedAt;

  @override
  List<Object?> get props => [id, title, tokensSpent, state, expiresAt, usedAt];
}

/// The code to show at the door: the typed code, and the live value the QR
/// carries, which changes every 30 seconds.
class PerkCode extends Equatable {
  const PerkCode({
    required this.code,
    required this.live,
    required this.refreshInSeconds,
    required this.title,
    this.expiresAt,
  });

  factory PerkCode.fromJson(Map<String, dynamic> json) => PerkCode(
        code: '${json['code']}',
        live: '${json['live']}',
        refreshInSeconds: (json['refreshInSeconds'] as num?)?.toInt() ?? 30,
        title: '${json['title'] ?? ''}',
        expiresAt: DateTime.tryParse('${json['expiresAt']}')?.toLocal(),
      );

  final String code;
  final String live;
  final int refreshInSeconds;
  final String title;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [code, live, refreshInSeconds, title, expiresAt];
}
