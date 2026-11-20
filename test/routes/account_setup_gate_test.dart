// The account setup gate (api#419): a Google account without a username or a
// password is kept on account setup, before onboarding and everything else,
// and leaves it as soon as both are set.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/routes/app_routes.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _googleUser = UserEntity(
  id: 'u1',
  email: 'g@example.com',
  name: 'Google Person',
  hasPassword: false,
  needsCredentialSetup: true,
);

const _setUpUser = UserEntity(
  id: 'u1',
  email: 'g@example.com',
  name: 'Google Person',
  username: 'new.name',
);

class _Signed extends AuthController {
  _Signed(this._user);

  final UserEntity _user;

  @override
  AuthState build() => AuthState(user: _user);

  /// What a successful setup leaves behind.
  void finishSetup() => state = const AuthState(user: _setUpUser);
}

void main() {
  late GoRouter router;
  late ProviderContainer container;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> boot(
    WidgetTester tester, {
    required UserEntity user,
    bool onboardingSeen = true,
  }) async {
    AppConfig.instance = const AppConfig.dev(useMock: true);
    SharedPreferences.setMockInitialValues({
      'welcome_seen': true,
      'onboarding_seen': onboardingSeen,
      'location_prompt_seen': true,
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => _Signed(user)),
        realtimeServiceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    router = container.read(goRouterProvider);
    await settle(tester);
  }

  String where() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 60));
  }

  testWidgets('a Google account without a password lands on account setup',
      (tester) async {
    await boot(tester, user: _googleUser);

    router.go(RouteNames.home);
    await settle(tester);
    expect(where(), RouteNames.accountSetup);

    // Nothing else opens until it's done.
    router.go(RouteNames.settings);
    await settle(tester);
    expect(where(), RouteNames.accountSetup);
    await finish(tester);
  });

  testWidgets('account setup comes before onboarding', (tester) async {
    await boot(tester, user: _googleUser, onboardingSeen: false);

    router.go(RouteNames.home);
    await settle(tester);
    expect(where(), RouteNames.accountSetup);

    (container.read(authControllerProvider.notifier) as _Signed).finishSetup();
    await settle(tester);
    expect(where(), RouteNames.onboarding);
    await finish(tester);
  });

  testWidgets('finishing setup leaves account setup by itself', (tester) async {
    await boot(tester, user: _googleUser);
    expect(where(), RouteNames.accountSetup);

    (container.read(authControllerProvider.notifier) as _Signed).finishSetup();
    await settle(tester);
    expect(where(), isNot(RouteNames.accountSetup));
    await finish(tester);
  });

  testWidgets('an account with nothing to set never sees account setup',
      (tester) async {
    await boot(tester, user: _setUpUser);

    router.go(RouteNames.accountSetup);
    await settle(tester);
    expect(where(), isNot(RouteNames.accountSetup));
    await finish(tester);
  });
}
