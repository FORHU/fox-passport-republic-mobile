import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/venue/domain/venue_detail.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';

/// Reads one venue in full.
class VenueRepository {
  VenueRepository(this._api);

  final ApiService _api;

  Future<VenueDetail> load(CatalogItem item) async {
    if (item.isSample) return VenueDetail.sample(item);
    final body = await _api.get(ApiEndpoints.venueById(item.id));
    // `{ venue: {...} }`, or the venue itself.
    final data = body is Map ? (body['venue'] ?? body['data'] ?? body) : null;
    if (data is! Map) throw const FormatException('No venue in the response');
    return VenueDetail.fromJson(data.cast<String, dynamic>());
  }
}

final venueRepositoryProvider = Provider<VenueRepository>(
  (ref) => VenueRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final venueDetailProvider =
    FutureProvider.autoDispose.family<VenueDetail, CatalogItem>(
  (ref, item) => ref.watch(venueRepositoryProvider).load(item),
);
