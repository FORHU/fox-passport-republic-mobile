import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/tickets/edit_request.dart';

/// Asking a venue to change a booking you hold.
class EditRequestsRepository {
  EditRequestsRepository(this._api);

  final ApiService _api;

  /// The latest request on [bookingId], or null when there never was one.
  Future<EditRequest?> latest(String bookingId) async {
    final body = await _api.get(
      ApiEndpoints.bookingEditRequests,
      query: {'bookingKind': 'booking', 'bookingId': bookingId},
    );
    final data = body is Map ? body['data'] : null;
    return data is Map
        ? EditRequest.fromJson(data.cast<String, dynamic>())
        : null;
  }

  /// Sends a request. Only what changes is sent; the API prices it and
  /// refuses what a booking cannot take.
  Future<EditRequest> create(
    String bookingId, {
    int? guests,
    DateTime? start,
    DateTime? end,
    String? reason,
  }) async {
    final note = reason?.trim() ?? '';
    final body = await _api.post(ApiEndpoints.bookingEditRequests, {
      'bookingKind': 'booking',
      'bookingId': bookingId,
      if (guests != null) 'proposedGuestCount': guests,
      if (start != null) 'proposedStartDate': start.toUtc().toIso8601String(),
      if (end != null) 'proposedEndDate': end.toUtc().toIso8601String(),
      if (note.isNotEmpty) 'reason': note,
    });
    final data = body is Map ? body['data'] : null;
    if (data is! Map) throw const FormatException('No request in the response');
    return EditRequest.fromJson(data.cast<String, dynamic>());
  }

  Future<void> withdraw(String requestId) async {
    await _api.patch(ApiEndpoints.bookingEditRequestWithdraw(requestId));
  }
}

final editRequestsRepositoryProvider = Provider<EditRequestsRepository>(
  (ref) => EditRequestsRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final editRequestProvider =
    FutureProvider.autoDispose.family<EditRequest?, String>((ref, bookingId) {
  ref.watch(currentUserIdProvider);
  return ref.watch(editRequestsRepositoryProvider).latest(bookingId);
});
