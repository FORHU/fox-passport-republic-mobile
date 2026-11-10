import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/domain/achievements.dart';

/// Reads the signed-in person's achievements. The server counts progress and
/// pays the tier rewards; this only reads them.
class AchievementsRepository {
  AchievementsRepository(this._api);

  final ApiService _api;

  Future<AchievementsSummary> mine() async {
    final body = await _api.get(ApiEndpoints.achievementsMe);
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Achievements response is missing data');
    }
    return AchievementsSummary.fromJson(data.cast<String, dynamic>());
  }
}

final achievementsRepositoryProvider = Provider<AchievementsRepository>(
  (ref) => AchievementsRepository(ref.watch(apiServiceProvider)),
);

/// The achievements; read again with `ref.invalidate`.
final FutureProvider<AchievementsSummary> achievementsProvider =
    FutureProvider.autoDispose<AchievementsSummary>((ref) {
  // Another account must not see this one's progress.
  ref.watch(currentUserIdProvider);
  return ref.watch(achievementsRepositoryProvider).mine();
});
