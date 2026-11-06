import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';

/// Reads the Foxer leaderboard.
class LeaderboardRepository {
  LeaderboardRepository(this._api);

  final ApiService _api;

  /// This month's "Most booked" board for [role], optionally for one [city].
  Future<FoxerBoard> foxers(LeaderboardRole role, {String? city}) async {
    final trimmed = city?.trim();
    final body = await _api.get(
      ApiEndpoints.leaderboardFoxers,
      query: {
        'role': role.api,
        'tab': 'most_booked',
        if (trimmed != null && trimmed.isNotEmpty) 'city': trimmed,
      },
    );
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Leaderboard response is missing data');
    }
    return FoxerBoard.fromJson(data.cast<String, dynamic>());
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(ref.watch(apiServiceProvider)),
);

/// The board for one role and city; read again with `ref.invalidate`.
// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final foxerBoardProvider =
    FutureProvider.autoDispose.family<FoxerBoard, BoardQuery>(
  (ref, query) => ref
      .watch(leaderboardRepositoryProvider)
      .foxers(query.role, city: query.city),
);
