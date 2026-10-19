import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _user = UserEntity(id: 'u1', email: 'ada@example.com', name: 'Ada');

/// A signed-in session whose sign-out answer the test chooses.
class _Session extends AuthController {
  static bool logoutSucceeds = true;
  static int logouts = 0;

  @override
  AuthState build() => const AuthState(user: _user);

  @override
  Future<bool> logout() async {
    logouts++;
    if (logoutSucceeds) state = const AuthState();
    return logoutSucceeds;
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _MockProfileRepository repo,
) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        profileRepositoryProvider.overrideWithValue(repo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfilePage(),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  late _MockProfileRepository repo;

  setUp(() {
    repo = _MockProfileRepository();
    _Session.logoutSucceeds = true;
    _Session.logouts = 0;
    when(repo.getProfile).thenAnswer(
      (_) async => Right(
        ProfileEntity(
          id: 'u1',
          name: 'Ada',
          email: 'ada@example.com',
          joinedAt: DateTime(2025, 3, 14),
        ),
      ),
    );
  });

  group('editing the name', () {
    testWidgets('shows who you are and when you joined', (tester) async {
      await _pump(tester, repo);

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('Member since March 2025'), findsOneWidget);
    });

    testWidgets('saves a new name and shows it everywhere', (tester) async {
      when(() => repo.updateName('Ada Byron'))
          .thenAnswer((_) async => const Right(unit));
      final container = await _pump(tester, repo);

      await tester.tap(find.text('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Ada Byron');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => repo.updateName('Ada Byron')).called(1);
      expect(find.text('Your name was updated.'), findsOneWidget);
      expect(container.read(authControllerProvider).user?.name, 'Ada Byron');
    });

    testWidgets('refuses a name that is not a name, without calling the API', (
      tester,
    ) async {
      await _pump(tester, repo);

      await tester.tap(find.text('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'R2D2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name can only contain letters'), findsOneWidget);
      verifyNever(() => repo.updateName(any()));
    });

    testWidgets('keeps the sheet open and says so when saving fails', (
      tester,
    ) async {
      when(() => repo.updateName(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Name is taken')),
      );
      final container = await _pump(tester, repo);

      await tester.tap(find.text('Edit name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Grace');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Name is taken'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(container.read(authControllerProvider).user?.name, 'Ada');
    });
  });

  group('signing out', () {
    testWidgets('asks first, and staying signed in does nothing', (
      tester,
    ) async {
      await _pump(tester, repo);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();

      expect(_Session.logouts, 0);
      expect(find.text('Sign out?'), findsNothing);
    });

    testWidgets('signs out once confirmed', (tester) async {
      await _pump(tester, repo);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
      await tester.pumpAndSettle();

      expect(_Session.logouts, 1);
    });

    testWidgets('says so when signing out did not work', (tester) async {
      _Session.logoutSucceeds = false;
      await _pump(tester, repo);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
      await tester.pumpAndSettle();

      expect(find.text("We couldn't sign you out. Try again."), findsOneWidget);
    });
  });
}
