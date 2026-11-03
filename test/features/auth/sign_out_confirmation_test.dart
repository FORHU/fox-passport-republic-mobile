import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/sign_out.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// A Sign out button that calls the real confirmation, as Settings does.
Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [authControllerProvider.overrideWith(_Session.new)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => confirmSignOut(context, ref),
                child: const Text('Sign out'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _Session.logoutSucceeds = true;
    _Session.logouts = 0;
  });

  group('signing out', () {
    testWidgets('asks first, and staying signed in does nothing', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();

      expect(_Session.logouts, 0);
      expect(find.text('Sign out?'), findsNothing);
    });

    testWidgets('signs out once confirmed', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
      await tester.pumpAndSettle();

      expect(_Session.logouts, 1);
    });

    testWidgets('says so when signing out did not work', (tester) async {
      _Session.logoutSucceeds = false;
      await _pump(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
      await tester.pumpAndSettle();

      expect(find.text("We couldn't sign you out. Try again."), findsOneWidget);
    });
  });
}
