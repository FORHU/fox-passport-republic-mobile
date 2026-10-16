import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';

class FavoritesRepository {
  FavoritesRepository(this._api, this._userId);

  final ApiService _api;
  final String? _userId;

  Future<Set<String>> loadIds() async {
    if (AppConfig.instance.useMock || _userId == null) return {};
    final body = await _api.get(ApiEndpoints.favoritesByUser(_userId));
    final rows = body is Map ? body['data'] : null;
    if (rows is! List) {
      throw const FormatException('Favorites response is not a list');
    }
    return {
      for (final row in rows)
        if (row is Map && row['targetId'] != null) '${row['targetId']}',
    };
  }

  Future<void> add(CatalogItem item) async {
    await _api.post(ApiEndpoints.favoriteAdd, {
      'targetId': item.id,
      'type': _type(item.kind),
    });
  }

  Future<void> remove(CatalogItem item) async {
    await _api.delete(ApiEndpoints.favoriteRemoveByListing, {
      'targetId': item.id,
      'type': _type(item.kind),
    });
  }

  static String _type(CatalogKind kind) => switch (kind) {
        CatalogKind.venues => 'venue',
        CatalogKind.events => 'public_event',
        CatalogKind.foxers ||
        CatalogKind.gear ||
        CatalogKind.services =>
          throw ArgumentError.value(kind, 'kind', 'Cannot be favorited'),
      };
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  return FavoritesRepository(ref.watch(apiServiceProvider), userId);
});

final FutureProvider<Set<String>> favoriteIdsProvider =
    FutureProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(favoritesRepositoryProvider).loadIds(),
);
