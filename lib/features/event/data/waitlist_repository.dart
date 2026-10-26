import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/event/domain/waitlist_status.dart';

/// The waitlist of a full event package: your place, joining and leaving.
class WaitlistRepository {
  WaitlistRepository(this._api);

  final ApiService _api;

  /// Your place on [templateId]'s waitlist. Works signed out too, then you
  /// are simply not on it.
  Future<WaitlistStatus> status(String templateId) async {
    final body = await _api.get(
      ApiEndpoints.waitlist,
      query: {'templateId': templateId},
    );
    return WaitlistStatus.fromJson(body is Map ? body['data'] : null);
  }

  /// Joins the waitlist. The API refuses when the event is not actually full
  /// (book it instead) or when you are on it already.
  Future<WaitlistStatus> join(String templateId) async {
    final body = await _api.post(
      ApiEndpoints.waitlist,
      {'templateId': templateId},
    );
    return WaitlistStatus.fromJson(body is Map ? body['data'] : null);
  }

  Future<void> leave(String entryId) async {
    await _api.delete(ApiEndpoints.waitlistEntry(entryId));
  }
}

final waitlistRepositoryProvider = Provider<WaitlistRepository>(
  (ref) => WaitlistRepository(ref.watch(apiServiceProvider)),
);

/// One event package's waitlist as the signed-in person sees it. Joining and
/// leaving change it; both throw when the server refuses, leaving it as it
/// was.
class WaitlistController extends AsyncNotifier<WaitlistStatus> {
  WaitlistController(this.templateId);

  final String templateId;

  @override
  Future<WaitlistStatus> build() {
    // A new account sees its own place, not the previous one's.
    ref.watch(currentUserIdProvider);
    return ref.read(waitlistRepositoryProvider).status(templateId);
  }

  /// Joins the waitlist; throws when the server refuses, leaving the place
  /// as it was.
  Future<void> join() async {
    final status = await ref.read(waitlistRepositoryProvider).join(templateId);
    state = AsyncData(status);
  }

  /// Leaves the waitlist; throws when the server refuses.
  Future<void> leave() async {
    final current = state.value;
    final entryId = current?.entryId;
    if (current == null || entryId == null) return;
    await ref.read(waitlistRepositoryProvider).leave(entryId);
    state = AsyncData(current.left);
  }
}

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final waitlistProvider = AsyncNotifierProvider.autoDispose
    .family<WaitlistController, WaitlistStatus, String>(
  WaitlistController.new,
);
