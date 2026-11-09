import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/foxers/foxer_score.dart';

/// Reads the signed-in Foxer's own Foxer Score.
class FoxerScoreSource {
  FoxerScoreSource(this._api);

  final ApiService _api;

  Future<FoxerScore> mine() async {
    final body = await _api.get(ApiEndpoints.foxerScoreMe);
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('No Foxer Score in the response');
    }
    return FoxerScore.fromJson(data.cast<String, dynamic>());
  }
}

final foxerScoreSourceProvider = Provider<FoxerScoreSource>(
  (ref) => FoxerScoreSource(ref.watch(apiServiceProvider)),
);

/// The Foxer's own score; read again with `ref.invalidate`.
final FutureProvider<FoxerScore> myFoxerScoreProvider =
    FutureProvider.autoDispose<FoxerScore>((ref) {
  // Another account must not see this one's score.
  ref.watch(currentUserIdProvider);
  return ref.watch(foxerScoreSourceProvider).mine();
});
