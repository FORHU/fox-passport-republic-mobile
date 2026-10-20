// Profile is opened from Passport and from Settings. It used to live inside
// the Passport tab, so opening it from Settings put the tab's page on the
// navigation stack twice and crashed ("!keyReservation.contains(key)").

import 'dart:async';

import 'package:flutter/widgets.dart';
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

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u1', email: 'ada@example.com', name: 'Ada'),
      );
}

void main() {
  late GoRouter router;

  Future<void> boot(WidgetTester tester) async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({
      'welcome_seen': true,
      'onboarding_seen': true,
      'location_prompt_seen': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(_Session.new),
        // No live chat socket: it would keep reconnecting for ever.
        realtimeServiceProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
    router = container.read(goRouterProvider);
    await tester.pump(const Duration(milliseconds: 500));
    // Not pumpAndSettle: some screens animate for ever while they load.
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Closes the app and lets the timers the live app keeps (realtime,
  /// retries) run out, so the test ends with none pending.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 60));
  }

  testWidgets('Settings opens Profile, and back returns to Settings', (
    tester,
  ) async {
    await boot(tester);
    router.go(RouteNames.passport);
    await settle(tester);
    unawaited(router.push<void>(RouteNames.settings));
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);

    // The first row is the person: their name, with their email under it.
    await tester.tap(find.text('Ada'));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);

    router.pop();
    await settle(tester);
    expect(find.text('Settings'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Edit profile opens from Profile, and from Settings', (
    tester,
  ) async {
    await boot(tester);
    router.go(RouteNames.passport);
    await settle(tester);
    unawaited(router.push<void>(RouteNames.settings));
    await settle(tester);

    await tester.tap(find.text('Edit profile'));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Edit profile'), findsWidgets);
    await finish(tester);
  });
}
