// Smoke tests: the app boots to the welcome carousel on first launch, then to
// the login page once the carousel has been seen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester, Map<String, Object> prefsValues) async {
  // Tests don't run bootstrap(), so set the active config manually.
  AppConfig.instance = const AppConfig.dev();
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows the welcome carousel before login',
      (tester) async {
    // The reel loops forever, so show still frames to let the app settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _boot(tester, {});

    expect(find.text('PLAN ANY'), findsOneWidget);
    expect(find.text('Create a free account'), findsOneWidget);
    expect(find.text('LOG IN TO YOUR ACCOUNT'), findsNothing);
  });

  testWidgets('shows the login page once the carousel has been seen',
      (tester) async {
    await _boot(tester, {'welcome_seen': true});

    // Eyebrow and hero headline are rendered upper-case (docs/mobile-design.md).
    expect(find.text('WELCOME BACK'), findsOneWidget);
    expect(find.text('LOG IN TO YOUR ACCOUNT'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });
}
