import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockStorageService extends Mock implements StorageService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: '1', email: 'ada@example.com', name: 'Ada'),
      );
}

Future<void> _pump(
  WidgetTester tester, {
  required MockProfileRepository repository,
  required Future<CitizenProfile> Function() citizen,
}) async {
  final storage = MockStorageService();
  when(storage.readUserModel).thenReturn(null);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        authControllerProvider.overrideWith(_Session.new),
        profileRepositoryProvider.overrideWithValue(repository),
        citizenProfileProvider.overrideWith((ref, id) => citizen()),
        citizenCountsProvider.overrideWith((ref, id) async => null),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'ProfilePage shows your profile as others see it, with your XP',
    (tester) async {
      final repository = MockProfileRepository();
      when(repository.getProfile).thenAnswer(
        (_) async => const Right(
          ProfileEntity(
            id: '1',
            name: 'Ada Lovelace',
            email: 'ada@example.com',
          ),
        ),
      );

      await _pump(
        tester,
        repository: repository,
        citizen: () async => CitizenProfile.tryParse({
          'id': '1',
          'name': 'Ada Lovelace',
          'bio': 'Building great things with Flutter.',
          'passport': {
            'paths': [
              {'path': 'user', 'level': 2, 'currentXP': 100},
            ],
          },
        })!,
      );

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(
        find.text('Building great things with Flutter.'),
        findsOneWidget,
      );
      // Your own XP, which others do not see.
      expect(find.text('100 / 400 XP (25%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ProfilePage says so, with a retry, when the profile does not load',
    (tester) async {
      final repository = MockProfileRepository();
      when(repository.getProfile)
          .thenAnswer((_) async => const Left(NetworkFailure()));

      await _pump(
        tester,
        repository: repository,
        citizen: () async => throw Exception('offline'),
      );

      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
