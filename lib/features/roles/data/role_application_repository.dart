import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// Sends an application for a role. The API keeps the documents private.
class RoleApplicationRepository {
  RoleApplicationRepository(this._api);

  final ApiService _api;

  Future<void> submit(RoleApplicationDraft draft) async {
    await _api.post(ApiEndpoints.roleRequestsApply, draft.toForm());
  }

  /// Replaces the documents an admin flagged. Each file is stored privately
  /// first, which gives its id; then the ids are sent for the request. [files]
  /// is keyed by the name the API reads the document under.
  Future<void> resubmit(
    String requestId,
    Map<String, PickedPhoto> files,
  ) async {
    final ids = <String, String>{};
    for (final entry in files.entries) {
      final body = await _api.upload(
        ApiEndpoints.uploadPrivate,
        FormData.fromMap({
          'file': MultipartFile.fromBytes(
            entry.value.bytes,
            filename: entry.value.name,
          ),
        }),
      );
      final id = body is Map ? body['fileId'] : null;
      if (id == null) throw const FormatException('The upload gave no file id');
      ids[entry.key] = '$id';
    }
    await _api.patch(
      ApiEndpoints.roleRequestResubmit(requestId),
      {'documents': ids},
    );
  }
}

final roleApplicationRepositoryProvider = Provider<RoleApplicationRepository>(
  (ref) => RoleApplicationRepository(ref.watch(apiServiceProvider)),
);
