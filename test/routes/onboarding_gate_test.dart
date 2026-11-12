// The onboarding gate (mobile#426): before onboarding is finished, every route
// goes back to onboarding, except the role application that onboarding's last
// step opens.

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

class _NewUser extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u1', email: 'new@example.com', name: 'New'),
      );
}

void main() {
  late GoRouter router;

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> boot(WidgetTester tester) async {
    AppConfig.instance = const AppConfig.dev(useMock: true);
    SharedPreferences.setMockInitialValues({
      'welcome_seen': true,
      'onboarding_seen': false,
      'location_prompt_seen': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(_NewUser.new),
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

  testWidgets('a new user lands on onboarding', (tester) async {
    await boot(tester);

    router.go(RouteNames.home);
    await settle(tester);

    expect(where(), RouteNames.onboarding);
    await finish(tester);
  });

  testWidgets('onboarding can open a role application', (tester) async {
    await boot(tester);

    router.go(RouteNames.roleApply('providerFoxer'));
    await settle(tester);
    expect(where(), RouteNames.roleApply('providerFoxer'));

    router.go(RouteNames.roleResubmit('r1'));
    await settle(tester);
    expect(where(), RouteNames.roleResubmit('r1'));
    await finish(tester);
  });
}
