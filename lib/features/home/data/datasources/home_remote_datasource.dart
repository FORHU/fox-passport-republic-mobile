import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/home/data/models/home_item_model.dart';

/// Talks to the remote API. Knows nothing about state or UI.
abstract class HomeRemoteDataSource {
  Future<List<HomeItemModel>> getItems();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl(this._api);

  final ApiService _api;

  @override
  Future<List<HomeItemModel>> getItems() async {
    final data = await _api.get(ApiEndpoints.users);
    final list = (data as Map)['data'] as List;
    return list
        .map(
          (e) => HomeItemModel.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }
}
