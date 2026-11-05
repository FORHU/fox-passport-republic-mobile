/// A reward Coins can buy: a discount voucher or a perk.
class RewardItem {
  const RewardItem({
    required this.id,
    required this.title,
    required this.coinCost,
    required this.minLevel,
    required this.canAfford,
    required this.levelQualified,
    this.description,
    this.discountPhp,
    this.discountPercentage,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
        id: '${json['id']}',
        title: (json['title'] as String?) ?? '',
        description: json['description'] as String?,
        coinCost: (json['coinCost'] as num?)?.toInt() ?? 0,
        discountPhp: (json['discountPhp'] as num?)?.toDouble(),
        discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
        minLevel: (json['minLevel'] as num?)?.toInt() ?? 1,
        canAfford: json['canAfford'] == true,
        levelQualified: json['levelQualified'] != false,
      );

  final String id;
  final String title;
  final String? description;
  final int coinCost;
  final double? discountPhp;
  final double? discountPercentage;

  /// The level the person must have reached.
  final int minLevel;

  /// The server says the balance covers the cost.
  final bool canAfford;

  /// The server says the person has reached [minLevel].
  final bool levelQualified;

  /// Takes money off a booking, rather than being a perk.
  bool get isDiscount => discountPhp != null || discountPercentage != null;
}

/// What redeeming a reward gave back: the voucher and the new balance.
class Redemption {
  const Redemption({
    required this.coinsSpent,
    required this.remainingCoins,
    required this.voucherCode,
    required this.expiresAt,
    this.discountPhp,
    this.discountPercentage,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    final voucher = (json['voucher'] as Map?)?.cast<String, dynamic>() ?? {};
    return Redemption(
      coinsSpent: (json['coinsSpent'] as num?)?.toInt() ?? 0,
      remainingCoins: (json['remainingCoins'] as num?)?.toInt() ?? 0,
      voucherCode: (voucher['code'] as String?) ?? '',
      discountPhp: (voucher['discountPhp'] as num?)?.toDouble(),
      discountPercentage: (voucher['discountPercentage'] as num?)?.toDouble(),
      expiresAt: DateTime.tryParse('${voucher['expiresAt']}')?.toLocal(),
    );
  }

  final int coinsSpent;
  final int remainingCoins;
  final String voucherCode;
  final double? discountPhp;
  final double? discountPercentage;
  final DateTime? expiresAt;
}
