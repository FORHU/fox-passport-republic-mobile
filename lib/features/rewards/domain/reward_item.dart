/// A reward Tokens can buy: a discount voucher or a perk. Anyone can redeem
/// what they can afford; there is no level lock.
class RewardItem {
  const RewardItem({
    required this.id,
    required this.title,
    required this.coinCost,
    required this.canAfford,
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
        canAfford: json['canAfford'] == true,
      );

  final String id;
  final String title;
  final String? description;
  final int coinCost;
  final double? discountPhp;
  final double? discountPercentage;

  /// The server says the balance covers the cost.
  final bool canAfford;

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
