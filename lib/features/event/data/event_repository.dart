import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/events/event_package.dart';

/// Reads one event package: what is in it, who runs it, what it costs.
class EventRepository {
  EventRepository(this._api);

  final ApiService _api;

  /// A sample row has no server-side event, so it is described locally.
  Future<EventPackage> load(CatalogItem item) async {
    if (item.isSample) return EventPackage.sample(item);
    final body = await _api.get(ApiEndpoints.eventBrowseById(item.id));
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) throw const FormatException('No event in the response');
    return EventPackage.fromJson(data.cast<String, dynamic>());
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final eventPackageProvider =
    FutureProvider.autoDispose.family<EventPackage, CatalogItem>(
  (ref, item) => ref.watch(eventRepositoryProvider).load(item),
);
