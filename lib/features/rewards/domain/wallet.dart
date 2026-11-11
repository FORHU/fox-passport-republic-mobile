/// One line in the Wallet history: a grant of Tokens, or something that changed
/// Tokens afterwards (spent, released, returned, reversed).
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.isGrant,
    required this.coinsDelta,
    required this.createdAt,
    this.action,
    this.lifecycleType,
    this.reason,
    this.refType,
    this.refId,
    this.isPending = false,
  });

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
        id: '${json['id']}',
        isGrant: json['type'] != 'lifecycle',
        action: json['action'] as String?,
        lifecycleType: json['lifecycleType'] as String?,
        coinsDelta: (json['coinsDelta'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String?,
        refType: json['refType'] as String?,
        refId: json['refId'] == null ? null : '${json['refId']}',
        isPending: json['isPending'] == true,
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;

  /// A grant is what an action paid; otherwise it changed an earlier grant.
  final bool isGrant;

  /// The reward rule behind a grant, such as `attendEvent`.
  final String? action;

  /// `RELEASE`, `REDEMPTION`, `VOUCHER_RETURN` or `REVERSAL`, for a change.
  final String? lifecycleType;

  /// Plus for Tokens earned or returned, minus for Tokens spent or reversed.
  final int coinsDelta;
  final String? reason;

  /// What a grant was for: `booking` and the booking's id, for an event
  /// attended.
  final String? refType;
  final String? refId;

  /// A grant whose Tokens are held until the first attended paid booking: they
  /// show as pending in the Wallet and are not counted as earned.
  final bool isPending;
  final DateTime createdAt;
}

/// The signed-in person's Tokens: what can be spent, what is waiting, and the
/// history behind both. Computed by the server; the app never adds Tokens up.
/// (The data and the API field names still say `coins`.)
class WalletSummary {
  const WalletSummary({
    required this.coins,
    required this.pendingCoins,
    required this.totalEarnedCoins,
    required this.history,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) => WalletSummary(
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        pendingCoins: (json['pendingCoins'] as num?)?.toInt() ?? 0,
        totalEarnedCoins: (json['totalEarnedCoins'] as num?)?.toInt() ?? 0,
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
  final List<WalletEntry> history;

  /// Nothing earned, spent or waiting yet.
  bool get isEmpty => coins == 0 && pendingCoins == 0 && history.isEmpty;
}
