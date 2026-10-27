import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/bid.dart';

/// The applications to supply an event, as the host or an Organizer sees them.
class BidsRepository {
  BidsRepository(this._api);

  final ApiService _api;

  /// Every service and gear bid on [eventId], newest first within each kind.
  Future<List<Bid>> forEvent(String eventId) async {
    Future<List<Bid>> load(String path, {required bool isService}) async {
      final body = await _api.get(path);
      final rows = body is Map ? body['data'] : body;
      if (rows is! List) {
        throw const FormatException('Bids response is not a list');
      }
      return [
        for (final row in rows)
          if (Bid.tryParse(row, isService: isService) case final b?) b,
      ];
    }

    final results = await Future.wait([
      load(ApiEndpoints.serviceBidsForEvent(eventId), isService: true),
      load(ApiEndpoints.assetBidsForEvent(eventId), isService: false),
    ]);
    return [...results[0], ...results[1]];
  }

  Future<void> accept(Bid bid) =>
      _api.patch(ApiEndpoints.bidAccept(bid.id, isService: bid.isService));

  Future<void> reject(Bid bid) =>
      _api.patch(ApiEndpoints.bidReject(bid.id, isService: bid.isService));
}

final bidsRepositoryProvider = Provider<BidsRepository>(
  (ref) => BidsRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final bidsProvider = FutureProvider.autoDispose.family<List<Bid>, String>(
  (ref, eventId) => ref.watch(bidsRepositoryProvider).forEvent(eventId),
);
