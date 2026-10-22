import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('the profile', () {
    testWidgets('shows who you are and when you joined', (tester) async {
      await _pump(tester, repo);

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('ada@example.com'), findsOneWidget);
      expect(find.text('Member since March 2025'), findsOneWidget);
    });

    testWidgets('shows the username and phone number too', (tester) async {
      when(repo.getProfile).thenAnswer(
        (_) async => const Right(
          ProfileEntity(
            id: 'u1',
            name: 'Ada',
            email: 'ada@example.com',
            username: 'ada_l',
            phone: '+639171234567',
          ),
        ),
      );
      await _pump(tester, repo);

      expect(find.text('@ada_l'), findsOneWidget);
      expect(find.text('+639171234567'), findsOneWidget);
    });

    testWidgets('has an Edit profile button, in place of Edit name', (
      tester,
    ) async {
      await _pump(tester, repo);

      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Edit name'), findsNothing);
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
