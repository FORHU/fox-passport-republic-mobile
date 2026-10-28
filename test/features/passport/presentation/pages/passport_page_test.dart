import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/passport/presentation/pages/passport_page.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'fox@example.com',
          name: 'Fox Partner',
          username: 'fox_partner',
          roleType: ['eventFoxer', 'investor'],
        ),
      );
}

void main() {
  testWidgets('shows the ID card, stamps and badges', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = MockStorageService();
    when(storage.readUserModel).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
          storageServiceProvider.overrideWithValue(storage),
          passportProvider.overrideWith(
            (ref) async => PassportSummary.sample(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PassportPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('REPUBLIC OF FOXERS'), findsOneWidget);
    // The level is the chip on the photo, as on the profile.
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('15 XP'), findsOneWidget);
    expect(find.text('LEVEL 2 AT 50'), findsOneWidget);
    // The Stamps tab pill and the Stamps section heading.
    expect(find.text('Stamps'), findsNWidgets(2));
    expect(find.text('2 OF 8'), findsOneWidget);
    expect(find.text('DVO'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('First night'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ID card matches the profile, and fits a narrow phone', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = MockStorageService();
    when(storage.readUserModel).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
          storageServiceProvider.overrideWithValue(storage),
          authControllerProvider.overrideWith(_Session.new),
          passportProvider.overrideWith(
            (ref) async => PassportSummary.sample(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // A narrow phone.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child!,
          ),
          home: const PassportPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fox Partner'), findsOneWidget);
    expect(find.text('@fox_partner'), findsOneWidget);
    // No photo yet: the initial, in the same rounded square as the profile.
    expect(find.text('F'), findsOneWidget);
    expect(find.text('EVENT FOXER'), findsOneWidget);
    expect(find.text('PARTNER FOXER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('PassportSummary', () {
    test('follows the API level curve', () {
      expect(PassportSummary.xpRequiredForLevel(1), 0);
      expect(PassportSummary.xpRequiredForLevel(2), 1000);
      expect(PassportSummary.xpRequiredForLevel(3), 2150);
    });

    test('works out level and progress from total XP', () {
      final s = PassportSummary.fromTotalXp(
        totalXp: 1575,
        stamps: const [],
        badges: const [],
      );
      expect(s.level, 2);
      expect(s.levelStartXp, 1000);
      expect(s.nextLevelXp, 2150);
      expect(s.progress, closeTo(0.5, 0.01));
    });
  });
}
