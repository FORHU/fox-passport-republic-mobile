import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';

/// Anyone's public profile, by id or username.
class CitizenRepository {
  CitizenRepository(this._api);

  final ApiService _api;

  Future<CitizenProfile> profile(String idOrUsername) async {
    final body = await _api.get(ApiEndpoints.publicProfile(idOrUsername));
    final profile = CitizenProfile.tryParse(body is Map ? body['data'] : null);
    if (profile == null) throw const FormatException('No such profile');
    return profile;
  }

  /// Followers and following, or null when they keep their numbers private.
  Future<CitizenFollowCounts?> counts(String userId) async {
    try {
      final body = await _api.get(ApiEndpoints.followCounts(userId));
      return CitizenFollowCounts.tryParse(body is Map ? body['data'] : null);
    } on AppException {
      return null;
    }
  }
}

final citizenRepositoryProvider = Provider<CitizenRepository>(
  (ref) => CitizenRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final citizenProfileProvider =
    FutureProvider.autoDispose.family<CitizenProfile, String>(
  (ref, id) => ref.watch(citizenRepositoryProvider).profile(id),
);

// Same as above: the family type is inferred.
// ignore: specify_nonobvious_property_types
final citizenCountsProvider =
    FutureProvider.autoDispose.family<CitizenFollowCounts?, String>(
  (ref, id) => ref.watch(citizenRepositoryProvider).counts(id),
);
