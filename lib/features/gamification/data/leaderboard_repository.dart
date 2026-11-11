import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';

/// Reads the Foxer leaderboard, the only leaderboard there is.
class LeaderboardRepository {
  LeaderboardRepository(this._api);

  final ApiService _api;

  /// The Foxer board for [role] and [tab], optionally for one [city].
  Future<FoxerBoard> foxers(
    LeaderboardRole role, {
    FoxerTab tab = FoxerTab.topRated,
    String? city,
  }) async {
    final trimmed = city?.trim();
    final body = await _api.get(
      ApiEndpoints.leaderboardFoxers,
      query: {
        'role': role.accountRole,
        'tab': tab.api,
        if (trimmed != null && trimmed.isNotEmpty) 'city': trimmed,
      },
    );
    return FoxerBoard.fromJson(_data(body), requestedRole: role);
  }

  static Map<String, dynamic> _data(Object? body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Leaderboard response is missing data');
    }
    return data.cast<String, dynamic>();
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) => LeaderboardRepository(ref.watch(apiServiceProvider)),
);

/// The Foxer board for one role, tab and city; read again with
/// `ref.invalidate`.
// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final foxerBoardProvider =
    FutureProvider.autoDispose.family<FoxerBoard, BoardQuery>(
  (ref, query) => ref
      .watch(leaderboardRepositoryProvider)
      .foxers(query.role, tab: query.tab, city: query.city),
);
