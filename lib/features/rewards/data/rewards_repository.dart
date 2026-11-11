import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/domain/reward_item.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';

/// Reads the Coins wallet and the rewards Coins can buy, and spends Coins. The
/// server owns every number: balance, what can be afforded, and the voucher.
class RewardsRepository {
  RewardsRepository(this._api);

  final ApiService _api;

  /// The wallet: the person's one balance of Tokens and the history behind it.
  Future<WalletSummary> wallet() async {
    final body = await _api.get(ApiEndpoints.rewardsMe);
    final data = _data(body);
    if (data == null) {
      throw const FormatException('Wallet response is missing data');
    }
    return WalletSummary.fromJson(data);
  }

  Future<List<RewardItem>> catalog() async {
    final body = await _api.get(ApiEndpoints.rewardsCatalog);
    final list = body is Map ? body['data'] : body;
    if (list is! List) {
      throw const FormatException('Rewards response is not a list');
    }
    return [
      for (final r in list)
        if (r is Map) RewardItem.fromJson(r.cast<String, dynamic>()),
    ];
  }

  /// Spends the Tokens for [rewardId] and returns the voucher. Throws an
  /// `AppException` with the server's reason when it refuses, such as too few
  /// Tokens.
  Future<Redemption> redeem(String rewardId) async {
    final data = _data(
      await _api.post(ApiEndpoints.rewardsRedeem, {'rewardId': rewardId}),
    );
    if (data == null) {
      throw const FormatException('Redeem response is missing data');
    }
    return Redemption.fromJson(data);
  }

  Map<String, dynamic>? _data(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is Map ? data.cast<String, dynamic>() : null;
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => RewardsRepository(ref.watch(apiServiceProvider)),
);

/// The wallet; read again with `ref.invalidate` after Coins change.
final FutureProvider<WalletSummary> walletProvider =
    FutureProvider.autoDispose<WalletSummary>(
  (ref) => ref.watch(rewardsRepositoryProvider).wallet(),
);

final FutureProvider<List<RewardItem>> rewardCatalogProvider =
    FutureProvider.autoDispose<List<RewardItem>>(
  (ref) => ref.watch(rewardsRepositoryProvider).catalog(),
);
