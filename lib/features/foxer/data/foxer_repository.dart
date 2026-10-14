import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/foxers/foxer_profile.dart';

/// Reads a Foxer's profile and sends Match requests.
class FoxerRepository {
  FoxerRepository(this._api);

  final ApiService _api;

  Future<FoxerProfile> load(CatalogItem item) async {
    if (item.isSample) return FoxerProfile.sample(item);
    final body = await _api.get(ApiEndpoints.foxerById(item.id));
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) throw const FormatException('No Foxer in the response');
    return FoxerProfile.fromJson(data.cast<String, dynamic>());
  }

  /// Asks a Foxer to take on an event. Nothing is charged: the Foxer accepts
  /// or declines first.
  Future<void> sendMatch(MatchRequest request, {required bool isSample}) async {
    if (isSample) return;
    final day = request.date;
    final message = request.message.trim();
    await _api.post(ApiEndpoints.matches, {
      'foxerId': request.foxerId,
      'style': request.style.isEmpty ? 'Own idea' : request.style,
      'date':
          DateTime(day.year, day.month, day.day, 18).toUtc().toIso8601String(),
      'guestCount': request.guests,
      if (message.isNotEmpty) 'requestContent': message,
    });
  }
}

final foxerRepositoryProvider = Provider<FoxerRepository>(
  (ref) => FoxerRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final foxerProfileProvider =
    FutureProvider.autoDispose.family<FoxerProfile, CatalogItem>(
  (ref, item) => ref.watch(foxerRepositoryProvider).load(item),
);
