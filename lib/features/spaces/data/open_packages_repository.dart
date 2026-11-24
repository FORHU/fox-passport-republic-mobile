import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/open_package.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';

/// Open packages and applications (api#460).
class OpenPackagesRepository {
  OpenPackagesRepository(this._api);

  final ApiService _api;

  /// Packages being put together by other Event Foxers.
  Future<List<OpenPackage>> list({String city = ''}) async {
    final body = await _api.get(
      ApiEndpoints.openPackages,
      query: {
        'limit': 50,
        if (city.trim().isNotEmpty) 'city': city.trim(),
      },
    );
    final data = body is Map ? body['data'] : null;
    final rows = data is Map ? data['packages'] : null;
    if (rows is! List) {
      throw const FormatException('Open packages response is missing data');
    }
    return [
      for (final r in rows)
        if (OpenPackage.tryParse(r) case final p?) p,
    ];
  }

  Future<OpenPackageDetail> detail(String id) async {
    final body = await _api.get(ApiEndpoints.openPackage(id));
    final detail = OpenPackageDetail.tryParse(body);
    if (detail == null) throw const FormatException('Open package is bad');
    return detail;
  }

  Future<void> apply(String id, ApplyChoice choice, {String message = ''}) =>
      _api.post(ApiEndpoints.openPackageApply(id), {
        'kind': choice.kind,
        'listingId': choice.id,
        if (message.trim().isNotEmpty) 'message': message.trim(),
      });

  Future<void> withdraw(String id, String applicationId) =>
      _api.delete(ApiEndpoints.openPackageWithdraw(id, applicationId));

  /// Applications to the caller's own package.
  Future<List<PackageApplication>> applications(String templateId) async {
    final body = await _api.get(ApiEndpoints.packageApplications(templateId));
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Applications response is missing data');
    }
    return [
      for (final r in data)
        if (PackageApplication.tryParse(r) case final a?) a,
    ];
  }

  /// Accepts an application, or declines it with [reason] (and [note],
  /// required for Other).
  Future<void> answer(
    String templateId,
    String applicationId, {
    required bool accept,
    InviteDeclineReason? reason,
    String? note,
  }) =>
      _api.patch(ApiEndpoints.packageApplication(templateId, applicationId), {
        'status': accept ? 'accepted' : 'declined',
        if (!accept && reason != null) 'reason': reason.api,
        if (!accept && note != null && note.trim().isNotEmpty)
          'note': note.trim(),
      });
}

final Provider<OpenPackagesRepository> openPackagesRepositoryProvider =
    Provider<OpenPackagesRepository>(
  (ref) => OpenPackagesRepository(ref.watch(apiServiceProvider)),
);

final FutureProvider<List<OpenPackage>> openPackagesProvider =
    FutureProvider.autoDispose<List<OpenPackage>>(
  (ref) => ref.watch(openPackagesRepositoryProvider).list(),
);

// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final openPackageProvider =
    FutureProvider.autoDispose.family<OpenPackageDetail, String>(
  (ref, id) => ref.watch(openPackagesRepositoryProvider).detail(id),
);

// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final packageApplicationsProvider =
    FutureProvider.autoDispose.family<List<PackageApplication>, String>(
  (ref, templateId) =>
      ref.watch(openPackagesRepositoryProvider).applications(templateId),
);
