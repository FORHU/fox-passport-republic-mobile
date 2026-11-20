// Account setup (api#419): only the missing fields are asked, the username is
// checked as it is typed, and the form sends only what the account lacks.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/pages/account_setup_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _goodPassword = 'Str0ng!Passw0rd';

class _FakeAuth extends AuthController {
  _FakeAuth(this._user, {this.taken = const {}, this.refusal});

  final UserEntity _user;
  final Set<String> taken;
  final String? refusal;
  final checked = <String>[];
  ({String? username, String? password})? sent;

  @override
  AuthState build() => AuthState(user: _user);

  @override
  Future<bool?> isUsernameAvailable(String username) async {
    checked.add(username);
    return !taken.contains(username);
  }

  @override
  Future<bool> setUpCredentials({String? username, String? password}) async {
    sent = (username: username, password: password);
    if (refusal != null) {
      state = AuthState(user: _user, error: refusal);
      return false;
    }
    state = AuthState(
      user: UserEntity(
        id: _user.id,
        email: _user.email,
        name: _user.name,
        username: username ?? _user.username,
      ),
    );
    return true;
  }
}

UserEntity _google({String username = '', bool hasPassword = false}) =>
    UserEntity(
      id: 'u1',
      email: 'g@example.com',
      name: 'Google Person',
      username: username,
      hasPassword: hasPassword,
      needsCredentialSetup: true,
    );

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<_FakeAuth> pump(WidgetTester tester, _FakeAuth auth) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => auth),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountSetupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  final username = find.byKey(const Key('account-setup-username'));
  final password = find.byKey(const Key('account-setup-password'));
  final confirm = find.byKey(const Key('account-setup-confirm'));

  Future<void> enter(WidgetTester tester, Finder field, String text) async {
    await tester.enterText(
      find.descendant(of: field, matching: find.byType(TextFormField)),
      text,
    );
    await tester.pump();
  }

  testWidgets('asks for a username and a password when both are missing',
      (tester) async {
    await pump(tester, _FakeAuth(_google()));
    expect(username, findsOneWidget);
    expect(password, findsOneWidget);
    expect(confirm, findsOneWidget);
  });

  testWidgets('asks only for the password when the username is set',
      (tester) async {
    await pump(tester, _FakeAuth(_google(username: 'kept.name')));
    expect(username, findsNothing);
    expect(password, findsOneWidget);
  });

  testWidgets('asks only for the username when the password is set',
      (tester) async {
    await pump(tester, _FakeAuth(_google(hasPassword: true)));
    expect(username, findsOneWidget);
    expect(password, findsNothing);
  });

  testWidgets('shows a taken username once typing pauses', (tester) async {
    final auth = await pump(tester, _FakeAuth(_google(), taken: {'taken'}));

    await enter(tester, username, 'Taken');
    await tester.pump(usernameCheckDelay);
    await tester.pump();

    expect(auth.checked, ['taken']);
    expect(find.text('Already taken'), findsOneWidget);
  });

  testWidgets("doesn't check a username that breaks the rule", (tester) async {
    final auth = await pump(tester, _FakeAuth(_google()));

    await enter(tester, username, 'no spaces');
    await tester.pump(usernameCheckDelay * 2);

    expect(auth.checked, isEmpty);
  });

  testWidgets("refuses passwords that don't match", (tester) async {
    final auth = await pump(tester, _FakeAuth(_google()));

    await enter(tester, username, 'new.name');
    await enter(tester, password, _goodPassword);
    await enter(tester, confirm, '${_goodPassword}x');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(auth.sent, isNull);
  });

  testWidgets('sends the lowercased username and the password', (tester) async {
    final auth = await pump(tester, _FakeAuth(_google()));

    await enter(tester, username, 'New.Name');
    await enter(tester, password, _goodPassword);
    await enter(tester, confirm, _goodPassword);
    await tester.pump(usernameCheckDelay);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(auth.sent, (username: 'new.name', password: _goodPassword));
  });

  testWidgets('sends only the password when that is all that is missing',
      (tester) async {
    final auth = await pump(tester, _FakeAuth(_google(username: 'kept.name')));

    await enter(tester, password, _goodPassword);
    await enter(tester, confirm, _goodPassword);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(auth.sent, (username: null, password: _goodPassword));
  });

  testWidgets("shows the API's refusal", (tester) async {
    final auth = await pump(
      tester,
      _FakeAuth(_google(hasPassword: true), refusal: 'Username already taken'),
    );

    await enter(tester, username, 'raced.name');
    await tester.pump(usernameCheckDelay);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(auth.sent?.username, 'raced.name');
    expect(find.text('Username already taken'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
