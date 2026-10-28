import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/domain/entities/identity_status.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// The optional government-ID check that earns the Verified badge.
class IdentityRepository {
  IdentityRepository(this._api);

  final ApiService _api;

  Future<IdentityStatus> status() async {
    final body = await _api.get(ApiEndpoints.identityMine);
    return IdentityStatus.fromJson(body is Map ? body['data'] : null);
  }

  /// Sends the ID (and optionally a selfie) for an admin to review. The API
  /// keeps them private.
  Future<void> submit({
    required IdType type,
    required PickedPhoto id,
    PickedPhoto? selfie,
  }) async {
    final form = FormData.fromMap({
      'idType': type.wire,
      'idFile': MultipartFile.fromBytes(id.bytes, filename: id.name),
      if (selfie != null)
        'selfieFile':
            MultipartFile.fromBytes(selfie.bytes, filename: selfie.name),
    });
    await _api.post(ApiEndpoints.identityVerification, form);
  }
}

final identityRepositoryProvider = Provider<IdentityRepository>(
  (ref) => IdentityRepository(ref.watch(apiServiceProvider)),
);

final FutureProvider<IdentityStatus> identityStatusProvider =
    FutureProvider.autoDispose<IdentityStatus>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(identityRepositoryProvider).status();
});
