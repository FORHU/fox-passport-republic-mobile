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

  /// The wallet. [path] is the XP path whose level and rank are wanted, as the
  /// API names it (`venueFoxer`, `eventFoxer`, ...); the Coins are the
  /// person's one balance whichever it is. Left out, it is the citizen's own.
  Future<WalletSummary> wallet({String? path}) async {
    final body = path == null
        ? await _api.get(ApiEndpoints.rewardsMe)
        : await _api.get(ApiEndpoints.rewardsMe, query: {'path': path});
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

  /// Spends the Coins for [rewardId] and returns the voucher. Throws an
  /// `AppException` with the server's reason when it refuses, such as too few
  /// Coins or a level not reached.
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

/// The wallet as seen from one XP path, for a Foxer space: its level and rank
/// are that role's, and the Coins are the same balance.
// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final walletForPathProvider =
    FutureProvider.autoDispose.family<WalletSummary, String>(
  (ref, path) => ref.watch(rewardsRepositoryProvider).wallet(path: path),
);
