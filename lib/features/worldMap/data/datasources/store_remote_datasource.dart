import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/worldMap/data/models/store_model.dart';

/// Talks to the remote API. Knows nothing about state or UI.
abstract class StoreRemoteDataSource {
  Future<List<StoreModel>> getNearbyStores();
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  StoreRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<List<StoreModel>> getNearbyStores() async {
    final data = await _api.get(ApiEndpoints.nearbyStores);
    final list = (data as Map)['data'] as List;
    return list
        .map(
          (e) => StoreModel.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }
}
