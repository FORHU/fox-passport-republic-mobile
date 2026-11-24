import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';

/// Package invites this person received as a Provider, and their answers
/// (api#447).
class PackageInvitesRepository {
  PackageInvitesRepository(this._api);

  final ApiService _api;

  Future<List<PackageInvite>> list() async {
    final body = await _api.get(ApiEndpoints.packageInvitesIncoming);
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Invites response is missing data');
    }
    return [
      for (final row in data)
        if (PackageInvite.tryParse(row) case final invite?) invite,
    ];
  }

  /// Joins the package, or declines it with [reason] (and [note], which the
  /// API requires for "Other").
  Future<void> respond(
    PackageInvite invite, {
    required bool accept,
    InviteDeclineReason? reason,
    String? note,
  }) async {
    await _api.patch(ApiEndpoints.packageInviteRespond(invite.id), {
      'type': invite.type,
      'status': accept ? 'accepted' : 'declined',
      if (!accept && reason != null) 'reason': reason.api,
      if (!accept && note != null && note.trim().isNotEmpty)
        'note': note.trim(),
    });
  }
}

final Provider<PackageInvitesRepository> packageInvitesRepositoryProvider =
    Provider<PackageInvitesRepository>(
  (ref) => PackageInvitesRepository(ref.watch(apiServiceProvider)),
);

/// Every invite this person received, newest answers included.
final FutureProvider<List<PackageInvite>> packageInvitesProvider =
    FutureProvider.autoDispose<List<PackageInvite>>(
  (ref) => ref.watch(packageInvitesRepositoryProvider).list(),
);
