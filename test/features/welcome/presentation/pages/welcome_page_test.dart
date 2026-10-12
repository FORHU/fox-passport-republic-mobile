import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> boot(WidgetTester tester, {Size? size}) async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    if (size != null) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on slide 1 with no Back link and a Skip link',
      (tester) async {
    await boot(tester);

    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('WELCOME TO FOXPASSPORT'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
  });

  testWidgets('Next walks the slides with the web copy and Back returns',
      (tester) async {
    await boot(tester);

    await tapNext(tester, 'Show me around');
    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('DISCOVER EXPERIENCES'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await tapNext(tester, 'Next');
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text('BOOK FOXERS IN ONE PLACE'), findsOneWidget);
    // Slide 3 shows the five role chips.
    for (final role in ['Event', 'Venue', 'Gear', 'Talent', 'Performer']) {
      expect(find.text(role), findsOneWidget);
    }

    await tapNext(tester, 'Back');
    expect(find.text('2 / 6'), findsOneWidget);
  });

  testWidgets('swiping changes slide', (tester) async {
    await boot(tester);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('DISCOVER EXPERIENCES'), findsOneWidget);

    // And back again.
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('1 / 6'), findsOneWidget);
  });

  testWidgets('Skip jumps to the last slide and hides itself', (tester) async {
    await boot(tester);

    await tapNext(tester, 'Skip');

    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('READY WHEN YOU ARE'), findsOneWidget);
    expect(find.text('Create a free account'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
    // Hidden, not removed: the row keeps its size but is not interactive.
    expect(find.text('Skip').hitTestable(), findsNothing);
  });

  testWidgets('"Create a free account" marks it seen and opens register',
      (tester) async {
    await boot(tester);

    await tapNext(tester, 'Skip');
    await tapNext(tester, 'Create a free account');

    expect(prefs.getBool('welcome_seen'), isTrue);
    expect(find.text('CREATE YOUR ACCOUNT'), findsOneWidget);
  });

  testWidgets('"I already have an account" marks it seen and opens login',
      (tester) async {
    await boot(tester);

    await tapNext(tester, 'Skip');
    await tapNext(tester, 'I already have an account');

    expect(prefs.getBool('welcome_seen'), isTrue);
    expect(find.text('LOG IN TO YOUR ACCOUNT'), findsOneWidget);
  });

  testWidgets('lays out on a small phone without overflow', (tester) async {
    await boot(tester, size: const Size(320, 568));

    for (var i = 0; i < 5; i++) {
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('6 / 6'), findsOneWidget);
  });
}
