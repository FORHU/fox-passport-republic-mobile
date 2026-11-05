/// One line in the Wallet history: a grant of XP and Coins, or something that
/// changed Coins afterwards (spent, released, expired, reversed).
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.isGrant,
    required this.xp,
    required this.coinsDelta,
    required this.createdAt,
    this.action,
    this.lifecycleType,
    this.reason,
  });

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
        id: '${json['id']}',
        isGrant: json['type'] != 'lifecycle',
        action: json['action'] as String?,
        lifecycleType: json['lifecycleType'] as String?,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        coinsDelta: (json['coinsDelta'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;

  /// A grant is what an action paid; otherwise it changed an earlier grant.
  final bool isGrant;

  /// The reward rule behind a grant, such as `attendEvent`.
  final String? action;

  /// `RELEASE`, `REDEMPTION`, `EXPIRY` or `REVERSAL`, for a change.
  final String? lifecycleType;
  final int xp;

  /// Plus for Coins earned, minus for Coins spent, expired or reversed.
  final int coinsDelta;
  final String? reason;
  final DateTime createdAt;
}

/// The signed-in person's Coins: what can be spent, what is waiting, and the
/// history behind both. Computed by the server; the app never adds Coins up.
class WalletSummary {
  const WalletSummary({
    required this.coins,
    required this.pendingCoins,
    required this.totalEarnedCoins,
    required this.level,
    required this.rank,
    required this.history,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        pendingCoins: (json['pendingCoins'] as num?)?.toInt() ?? 0,
        totalEarnedCoins: (json['totalEarnedCoins'] as num?)?.toInt() ?? 0,
        level: (json['level'] as num?)?.toInt() ?? 1,
        rank: (json['rank'] as String?) ?? '',
        history: [
          for (final e in (json['history'] as List? ?? const []))
            if (e is Map) WalletEntry.fromJson(e.cast<String, dynamic>()),
        ],
      );

  /// Spendable now.
  final int coins;

  /// Earned, but not spendable until it is safe from a refund.
  final int pendingCoins;
  final int totalEarnedCoins;
  final int level;
  final String rank;
  final List<WalletEntry> history;

  /// Nothing earned, spent or waiting yet.
  bool get isEmpty => coins == 0 && pendingCoins == 0 && history.isEmpty;
}
