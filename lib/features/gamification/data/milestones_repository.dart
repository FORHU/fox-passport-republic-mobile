import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';

/// Reads the signed-in person's milestones. The server counts progress and
/// pays the tiers; this only reads them.
class MilestonesRepository {
  MilestonesRepository(this._api);

  final ApiService _api;

  Future<MilestonesSummary> mine() async {
    final body = await _api.get(ApiEndpoints.milestonesMe);
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Milestones response is missing data');
    }
    return MilestonesSummary.fromJson(data.cast<String, dynamic>());
  }
}

final milestonesRepositoryProvider = Provider<MilestonesRepository>(
  (ref) => MilestonesRepository(ref.watch(apiServiceProvider)),
);

/// The milestones; read again with `ref.invalidate`.
final FutureProvider<MilestonesSummary> milestonesProvider =
    FutureProvider.autoDispose<MilestonesSummary>((ref) {
  // Another account must not see this one's progress.
  ref.watch(currentUserIdProvider);
  return ref.watch(milestonesRepositoryProvider).mine();
});
