import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/domain/provider_application.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/domain/tax_id.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// Sends an application for a role. The API keeps the documents private.
class RoleApplicationRepository {
  RoleApplicationRepository(this._api);

  final ApiService _api;

  Future<void> submit(RoleApplicationDraft draft) async {
    await _api.post(ApiEndpoints.roleRequestsApply, draft.toForm());
  }

  /// The countries a tax number can be from (mobile#529).
  Future<List<TaxCountry>> taxCountries() async {
    final body = await _api.get(ApiEndpoints.locationCountries);
    final rows = body is Map ? body['data'] : body;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (TaxCountry.tryParse(row) case final c?) c,
    ];
  }

  /// The country on the person's profile, as `GET /profile` gives it (a code
  /// or a name), or ''.
  Future<String> profileCountry() async {
    final body = await _api.get(ApiEndpoints.profile);
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    return data is Map ? '${data['country'] ?? ''}'.trim() : '';
  }

  /// How [countryCode]'s tax numbers look, or null when the API gives none.
  Future<TinFormats?> tinFormats(String countryCode) async =>
      TinFormats.tryParse(
        await _api.get(ApiEndpoints.locationTinFormats(countryCode)),
      );

  /// Sends a Provider's wizard application (mobile#487). The work photos are
  /// stored privately first, which gives their ids; then the application
  /// names them per specialty, with the documents attached as files.
  Future<void> submitProvider(ProviderApplicationDraft draft) async {
    final photoIds = <String, List<String>>{};
    for (final slug in draft.specializations) {
      final ids = <String>[];
      for (final photo in draft.detailFor(slug).photos) {
        final body = await _api.upload(
          ApiEndpoints.uploadPrivate,
          FormData.fromMap({
            'file': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
          }),
        );
        final id = body is Map ? body['fileId'] : null;
        if (id == null) {
          throw const FormatException('The upload gave no file id');
        }
        ids.add('$id');
      }
      photoIds[slug] = ids;
    }
    await _api.post(ApiEndpoints.roleRequestsApply, draft.toForm(photoIds));
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
          // A portfolio is a PDF or Word document, checked as one (app#371).
          if (entry.key == portfolioFileField) 'purpose': 'portfolio',
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
