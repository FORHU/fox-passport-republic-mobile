import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/shared/onboarding/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

void main() {
  late _MockApi api;
  late OnboardingRepository repo;

  setUp(() {
    api = _MockApi();
    repo = OnboardingRepository(api);
  });

  group('completedSteps', () {
    test('reads the names of the finished steps', () async {
      when(() => api.get(ApiEndpoints.onboarding)).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'steps': [
              {'step': 'intro', 'completedAt': '2026-11-06T00:00:00.000Z'},
              {'step': 'profile_complete', 'completedAt': 'x'},
            ],
          },
        },
      );

      expect(await repo.completedSteps(), {'intro', 'profile_complete'});
    });

    test('is empty for an account that has finished nothing', () async {
      when(() => api.get(ApiEndpoints.onboarding)).thenAnswer(
        (_) async => {
          'data': {'steps': <Object>[]},
        },
      );

      expect(await repo.completedSteps(), isEmpty);
    });

    test('refuses a reply with no steps rather than guessing', () async {
      when(() => api.get(ApiEndpoints.onboarding))
          .thenAnswer((_) async => {'data': <String, dynamic>{}});

      expect(repo.completedSteps(), throwsFormatException);
    });
  });

  group('complete', () {
    test('reports the step and returns what it paid', () async {
      when(() => api.post('/onboarding/intro', any())).thenAnswer(
        (_) async => {
          'data': {
            'step': 'intro',
            'alreadyCompleted': false,
            'reward': {'coinsAwarded': 20},
          },
        },
      );

      final reward = await repo.complete(OnboardingStep.intro);

      expect(reward.coins, 20);
      expect(reward.isNone, isFalse);
    });

    test('pays nothing for a step reported before', () async {
      when(() => api.post('/onboarding/intro', any())).thenAnswer(
        (_) async => {
          'data': {
            'alreadyCompleted': true,
            'reward': {'xpAwarded': 0, 'coinsAwarded': 0},
          },
        },
      );

      expect((await repo.complete(OnboardingStep.intro)).isNone, isTrue);
    });

    test('treats a reply with no reward as none', () async {
      when(() => api.post('/onboarding/intro', any()))
          .thenAnswer((_) async => {'data': <String, dynamic>{}});

      expect((await repo.complete(OnboardingStep.intro)).isNone, isTrue);
    });
  });

  test('step names match the server', () {
    expect(OnboardingStep.intro, 'intro');
    expect(OnboardingStep.profileComplete, 'profile_complete');
    expect(OnboardingStep.idVerified, 'id_verified');
    expect(ApiEndpoints.onboardingStep('intro'), '/onboarding/intro');
  });
}
