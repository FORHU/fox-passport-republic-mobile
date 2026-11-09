import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// The steps the server records, by the names it uses. `intro` is the citizen
/// tour, reported by the app. `profile_complete` and `id_verified` are worked
/// out by the server from the account and cannot be reported.
abstract final class OnboardingStep {
  static const String intro = 'intro';
  static const String profileComplete = 'profile_complete';
  static const String idVerified = 'id_verified';
}

/// What reporting a step paid. Zero when it had been reported before.
class StepReward {
  const StepReward({required this.xp, required this.coins});

  static const none = StepReward(xp: 0, coins: 0);

  final int xp;
  final int coins;

  bool get isNone => xp == 0 && coins == 0;
}

/// Reads which onboarding steps the account has finished, and reports the tour.
/// The server owns the state and the reward: a new phone or a reinstall does
/// not replay a finished tour, and a step pays once.
class OnboardingRepository {
  OnboardingRepository(this._api);

  final ApiService _api;

  /// The names of the steps this account has finished.
  Future<Set<String>> completedSteps() async {
    final body = await _api.get(ApiEndpoints.onboarding);
    final data = body is Map ? body['data'] : null;
    final steps = data is Map ? data['steps'] : null;
    if (steps is! List) {
      throw const FormatException('Onboarding response is missing steps');
    }
    return {
      for (final s in steps)
        if (s is Map && s['step'] is String) s['step'] as String,
    };
  }

  /// Reports [step] as finished. Safe to repeat: the server pays once.
  Future<StepReward> complete(String step) async {
    final body = await _api.post(ApiEndpoints.onboardingStep(step), const {});
    final data = body is Map ? body['data'] : null;
    final reward = data is Map ? data['reward'] : null;
    if (reward is! Map) return StepReward.none;
    return StepReward(
      xp: (reward['xpAwarded'] as num?)?.toInt() ?? 0,
      coins: (reward['coinsAwarded'] as num?)?.toInt() ?? 0,
    );
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(apiServiceProvider)),
);

/// The finished steps for whoever is signed in; read again with
/// `ref.invalidate` after reporting one or finishing a profile or ID check.
final FutureProvider<Set<String>> onboardingStepsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) {
  // Another account must not see this one's steps.
  ref.watch(currentUserIdProvider);
  return ref.watch(onboardingRepositoryProvider).completedSteps();
});
