import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/promotion.dart';

/// A Foxer's own promotions. The API only lets them touch their own.
class PromotionsRepository {
  PromotionsRepository(this._api);

  final ApiService _api;

  Future<List<Promotion>> mine() async {
    final body = await _api.get(ApiEndpoints.promotionsMine);
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) {
      throw const FormatException('Promotions response is not a list');
    }
    return [
      for (final row in rows)
        if (Promotion.tryParse(row) case final p?) p,
    ];
  }

  Future<void> create(PromotionDraft draft) async {
    await _api.post(ApiEndpoints.promotionsMine, draft.toJson());
  }

  Future<void> setActive(String id, {required bool active}) async {
    await _api.put(ApiEndpoints.promotionMine(id), {'active': active});
  }

  Future<void> remove(String id) async {
    await _api.delete(ApiEndpoints.promotionMine(id));
  }
}

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => PromotionsRepository(ref.watch(apiServiceProvider)),
);

final FutureProvider<List<Promotion>> promotionsProvider =
    FutureProvider.autoDispose<List<Promotion>>(
  (ref) => ref.watch(promotionsRepositoryProvider).mine(),
);
