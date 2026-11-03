import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/features/settings/presentation/pages/change_password_page.dart';
import 'package:flutter_template/features/settings/presentation/widgets/delete_account_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _Session extends AuthController {
  static int clears = 0;

  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u1', email: 'a@b.co', name: 'Ada'),
      );

  @override
  Future<void> onUnauthenticated() async {
    clears++;
  }
}

const _strong = 'Str0ng!Passw0rd#2026';

void main() {
  late _MockProfileRepository repo;

  setUp(() {
    repo = _MockProfileRepository();
    _Session.clears = 0;
    when(repo.getProfile).thenAnswer(
      (_) async => const Right(
        ProfileEntity(id: 'u1', name: 'Ada', email: 'a@b.co'),
      ),
    );
  });

  Widget app(Widget home, {GoRouter? router}) => ProviderScope(
        retry: (_, __) => null,
        overrides: [
          authControllerProvider.overrideWith(_Session.new),
          profileRepositoryProvider.overrideWithValue(repo),
        ],
        child: router == null
            ? MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: home,
              )
            : MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
      );

  group('change password', () {
    Future<GoRouter> pump(WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('BACK')),
          GoRoute(
            path: '/password',
            builder: (_, __) => const ChangePasswordPage(),
          ),
        ],
      );
      await tester.pumpWidget(app(const SizedBox(), router: router));
      await tester.pumpAndSettle();
      unawaited(router.push<void>('/password'));
      await tester.pumpAndSettle();
      return router;
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('sends the current and the new password, then goes back', (
      tester,
    ) async {
      when(
        () => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async => const Right(unit));
      await pump(tester);

      await tester.enterText(field('Current password'), 'old-password');
      await tester.enterText(field('New password'), _strong);
      await tester.enterText(field('Confirm new password'), _strong);
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      verify(
        () => repo.changePassword(
          currentPassword: 'old-password',
          newPassword: _strong,
        ),
      ).called(1);
      expect(find.text('BACK'), findsOneWidget);
    });

    testWidgets('refuses a weak new password, without calling the API', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(field('Current password'), 'old-password');
      await tester.enterText(field('New password'), 'short');
      await tester.enterText(field('Confirm new password'), 'short');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 16 characters'),
        findsOneWidget,
      );
      verifyNever(
        () => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWidgets('refuses a confirmation that does not match', (tester) async {
      await pump(tester);

      await tester.enterText(field('Current password'), 'old-password');
      await tester.enterText(field('New password'), _strong);
      await tester.enterText(field('Confirm new password'), '${_strong}x');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('stays put and says why when the API refuses', (tester) async {
      when(
        () => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure('Current password is incorrect')),
      );
      await pump(tester);

      await tester.enterText(field('Current password'), 'wrong-password');
      await tester.enterText(field('New password'), _strong);
      await tester.enterText(field('Confirm new password'), _strong);
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });
  });

  group('delete account', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeleteAccountSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('needs the password and the word DELETE', (tester) async {
      await open(tester);

      expect(find.text('Delete your account?'), findsOneWidget);
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.deleteAccount(any()));
      expect(_Session.clears, 0);
    });

    testWidgets('a wrong word does not delete', (tester) async {
      await open(tester);

      await tester.enterText(field('Confirm your password'), 'pw');
      await tester.enterText(field('Type DELETE to confirm'), 'delete');
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.deleteAccount(any()));
    });

    testWidgets('deletes the account and ends the session', (tester) async {
      when(() => repo.deleteAccount('pw'))
          .thenAnswer((_) async => const Right(unit));
      await open(tester);

      await tester.enterText(field('Confirm your password'), 'pw');
      await tester.enterText(field('Type DELETE to confirm'), 'DELETE');
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      verify(() => repo.deleteAccount('pw')).called(1);
      expect(_Session.clears, 1);
      expect(find.text('Delete your account?'), findsNothing);
    });

    testWidgets('a wrong password keeps the account and the session', (
      tester,
    ) async {
      when(() => repo.deleteAccount(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Invalid password')),
      );
      await open(tester);

      await tester.enterText(field('Confirm your password'), 'nope');
      await tester.enterText(field('Type DELETE to confirm'), 'DELETE');
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid password'), findsOneWidget);
      expect(_Session.clears, 0);
      expect(find.text('Delete your account?'), findsOneWidget);
    });
  });
}
