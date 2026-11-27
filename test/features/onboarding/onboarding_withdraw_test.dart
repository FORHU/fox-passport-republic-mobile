import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_template/features/onboarding/domain/entities/onboarding_models.dart';
import 'package:flutter_template/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// api#367: withdrawing an application under review from the onboarding
/// roles step, and the card coming back as one to apply for.

class _MockRepo extends Mock implements OnboardingRepository {}

const _user = UserEntity(id: 'u1', email: 'ada@example.com', name: 'Ada');

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(user: _user);
}

const _pending = RoleRequestSummary(
  id: 'r1',
  roleType: 'eventFoxer',
  status: 'pending',
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.fetchProfile())
        .thenAnswer((_) async => const Right(ProfileSeed(name: 'Ada')));
    when(() => repo.fetchCountries())
        .thenAnswer((_) async => const Right(<GeoCountry>[]));
  });

  Future<ProviderContainer> loaded(List<RoleRequestSummary> requests) async {
    when(() => repo.fetchMyRoleRequests())
        .thenAnswer((_) async => Right(requests));
    final c = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        onboardingRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(onboardingControllerProvider, (_, __) {});
    // Let the first load finish.
    while (c.read(onboardingControllerProvider).isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    return c;
  }

  test('keeps each application under review with its id', () async {
    final c = await loaded(const [_pending]);

    final state = c.read(onboardingControllerProvider);
    expect(state.pendingRoles, ['eventFoxer']);
    expect(state.pendingRequests, [_pending]);
  });

  test('withdraws it, and the role is no longer under review', () async {
    final c = await loaded(const [_pending]);
    when(() => repo.withdrawRoleRequest(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => repo.fetchMyRoleRequests()).thenAnswer(
      (_) async => const Right([
        RoleRequestSummary(
          id: 'r1',
          roleType: 'eventFoxer',
          status: 'withdrawn',
        ),
      ]),
    );

    final error =
        await c.read(onboardingControllerProvider.notifier).withdraw('r1');

    expect(error, isNull);
    verify(() => repo.withdrawRoleRequest('r1')).called(1);
    final state = c.read(onboardingControllerProvider);
    expect(state.pendingRoles, isEmpty);
    expect(state.pendingRequests, isEmpty);
  });

  test("answers with the API's reason and shows where it stands now", () async {
    final c = await loaded(const [_pending]);
    when(() => repo.withdrawRoleRequest(any())).thenAnswer(
      (_) async => const Left(
        ServerFailure(
          "This application was already approved and can't be withdrawn",
        ),
      ),
    );
    when(() => repo.fetchMyRoleRequests()).thenAnswer(
      (_) async => const Right([
        RoleRequestSummary(
          id: 'r1',
          roleType: 'eventFoxer',
          status: 'approved',
        ),
      ]),
    );

    final error =
        await c.read(onboardingControllerProvider.notifier).withdraw('r1');

    expect(
      error,
      "This application was already approved and can't be withdrawn",
    );
    expect(c.read(onboardingControllerProvider).pendingRoles, isEmpty);
  });
}
