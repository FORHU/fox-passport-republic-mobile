import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/welcome/presentation/widgets/reel_night_map.dart';
import 'package:flutter_template/features/welcome/presentation/widgets/reel_scenes.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  /// Boots the app on the welcome reel. With [reduceMotion] the reel shows
  /// still frames that only move on a tap, which lets `pumpAndSettle` finish;
  /// without it the scenes loop forever, so those tests pump by hand.
  /// [screenReader] turns on the platform's accessible navigation.
  Future<void> boot(
    WidgetTester tester, {
    Size? size,
    bool reduceMotion = true,
    bool screenReader = false,
  }) async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    if (size != null) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    if (reduceMotion || screenReader) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(
        disableAnimations: reduceMotion,
        accessibleNavigation: screenReader,
      );
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    );
    if (reduceMotion) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // A scene is 6.5 s, then the next one fades in over 0.5 s.
  Future<void> playScene(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 6600));
    await tester.pump(const Duration(milliseconds: 700));
  }

  // Taps and swipes in the stage, clear of the buttons: the screen is 800
  // wide, so the left third ends near 280.
  const left = Offset(80, 150);
  const middle = Offset(400, 150);
  const right = Offset(720, 150);

  testWidgets('starts on scene 1 with sign-up and log in in reach', (
    tester,
  ) async {
    await boot(tester);

    expect(find.text('PLAN ANY'), findsOneWidget);
    expect(find.text('OCCASION'), findsOneWidget);
    expect(find.text('Create a free account'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    // One way to move: no Skip, Next or Back buttons.
    for (final gone in ['Skip', 'Next', 'Back', 'Show me around']) {
      expect(find.text(gone), findsNothing);
    }
  });

  testWidgets('tap goes on anywhere but the left third, which goes back', (
    tester,
  ) async {
    await boot(tester);

    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text("WHAT'S ON"), findsOneWidget);
    expect(find.text('NEAR YOU'), findsOneWidget);

    await tester.tapAt(middle);
    await tester.pumpAndSettle();
    expect(find.text('TICKETS AND'), findsOneWidget);
    expect(find.text('STAMPS'), findsOneWidget);

    // On the last scene a tap on goes nowhere.
    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text('TICKETS AND'), findsOneWidget);

    await tester.tapAt(left);
    await tester.pumpAndSettle();
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('swipe left goes on and swipe right goes back', (tester) async {
    await boot(tester);

    await tester.dragFrom(middle, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text("WHAT'S ON"), findsOneWidget);

    await tester.dragFrom(middle, const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(find.text('PLAN ANY'), findsOneWidget);
  });

  testWidgets('arrow keys move between scenes', (tester) async {
    await boot(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text("WHAT'S ON"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('PLAN ANY'), findsOneWidget);
  });

  testWidgets('each scene shows its own copy and art', (tester) async {
    await boot(tester);

    // 1 · plan any occasion: four occasion tiles and what to book for each.
    expect(
      find.text(
        'Weddings, birthdays, corporate nights and nights out: book the '
        'venue, the gear and the crew in one app.',
      ),
      findsOneWidget,
    );
    for (final text in [
      'Wedding',
      'Venue · Catering',
      'Birthday',
      'Venue · Sound',
      'Corporate',
      'Hall · Catering',
      'Night out',
      'Rooftop · DJ',
    ]) {
      expect(find.text(text), findsOneWidget);
    }

    // 2 · what's on near you.
    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(
      find.text(
        'Events this week, and venues free on your date, from Metro Manila '
        'to Cebu and Davao.',
      ),
      findsOneWidget,
    );
    expect(find.text('Every Foxer is verified'), findsOneWidget);

    // 3 · tickets and stamps: a ticket over a passport page of stamps.
    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text('YOUR PASSPORT'), findsOneWidget);
    for (final text in ['TAG', 'MNL', 'CEB', 'CONFIRMED', 'Garden Wedding']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('Works\noffline'), findsOneWidget);
  });

  testWidgets('scene 2 shows the Mapbox globe and the others do not', (
    tester,
  ) async {
    await boot(tester);
    expect(find.byType(RotatingGlobe), findsNothing);

    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.byType(RotatingGlobe), findsOneWidget);

    // Neon look, held on the Philippines, with a pin on each listing city and
    // routes from Metro Manila (the first stop).
    final globe = tester.widget<RotatingGlobe>(find.byType(RotatingGlobe));
    expect(globe.look, GlobeLook.neon);
    expect(globe.spin, isTrue);
    expect(globe.zoom, 3.5);
    // Turning slowly, slower than the Home hero.
    expect(globe.degreesPerSecond, lessThan(5));
    expect(globe.nightLights, isTrue);
    expect(globe.stops.map((s) => s.city), [
      'Metro Manila',
      'Baguio',
      'Clark',
      'Cebu',
      'Davao',
    ]);

    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.byType(RotatingGlobe), findsNothing);
  });

  testWidgets('the occasion tiles scale up to fill a tall phone', (
    tester,
  ) async {
    await boot(tester, size: const Size(400, 850));

    // The grid is drawn 274 wide; on a 400-wide phone it should be a good deal
    // wider, not left small in the middle of an empty stage.
    final grid = tester.getRect(
      find.descendant(
        of: find.byType(ReelScene),
        matching: find.byType(Wrap),
      ),
    );
    expect(grid.width, greaterThan(330));
    expect(grid.width, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);
  });

  testWidgets('with motion on the globe starts east of the Philippines', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 700));

    // It turns west over the scene, so it starts that far east of the islands
    // (122.5°E) and passes over them while the scene plays.
    final globe = tester.widget<RotatingGlobe>(find.byType(RotatingGlobe));
    expect(globe.startLng, greaterThan(122.5));
    expect(globe.startLng - globe.degreesPerSecond * 6.5, lessThan(122.5));
  });

  testWidgets('with reduced motion the globe sits right on the Philippines', (
    tester,
  ) async {
    await boot(tester);
    await tester.tapAt(right);
    await tester.pumpAndSettle();

    // It does not turn, so there is no reason to start it off to one side.
    final globe = tester.widget<RotatingGlobe>(find.byType(RotatingGlobe));
    expect(globe.startLng, 122.5);
  });

  testWidgets('a still night map shows where the live globe cannot', (
    tester,
  ) async {
    await boot(tester);
    await tester.tapAt(right);
    await tester.pumpAndSettle();

    // With no Mapbox token (as here) the still picture is the slide's globe,
    // so the slide is never blank.
    final globe = tester.widget<RotatingGlobe>(find.byType(RotatingGlobe));
    expect(globe.still, isA<ReelNightMap>());
    // Its cities ping and its routes flow off the reel's own clock.
    expect((globe.still! as ReelNightMap).ambient, isNotNull);
    expect(find.byType(ReelNightMap), findsOneWidget);
  });

  testWidgets('pausing or holding freezes the globe too', (tester) async {
    await boot(tester, reduceMotion: false);
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 700));

    bool frozen() =>
        tester.widget<RotatingGlobe>(find.byType(RotatingGlobe)).paused;
    expect(frozen(), isFalse);

    // The pause button.
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(frozen(), isTrue);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(frozen(), isFalse);

    // A finger held down.
    final finger = await tester.startGesture(const Offset(400, 150));
    await tester.pump(const Duration(milliseconds: 300));
    expect(frozen(), isTrue);
    await finger.up();
    await tester.pump();
    expect(frozen(), isFalse);
  });

  testWidgets('"Create a free account" marks it seen and opens register', (
    tester,
  ) async {
    await boot(tester);

    await tester.tap(find.text('Create a free account'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('welcome_seen'), isTrue);
    expect(find.text('CREATE YOUR ACCOUNT'), findsOneWidget);
  });

  testWidgets('"Log in" marks it seen and opens login, from any scene', (
    tester,
  ) async {
    await boot(tester);

    await tester.tapAt(right);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('welcome_seen'), isTrue);
    expect(find.text('LOG IN TO YOUR ACCOUNT'), findsOneWidget);
  });

  testWidgets('plays on its own and waits on the last scene', (tester) async {
    await boot(tester, reduceMotion: false);
    expect(find.text('PLAN ANY'), findsOneWidget);

    for (final headline in ["WHAT'S ON", 'TICKETS AND']) {
      await playScene(tester);
      expect(find.text(headline), findsOneWidget);
    }

    // It does not loop back: the last scene stays.
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('TICKETS AND'), findsOneWidget);
    expect(find.text('Create a free account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap during playback moves on and the timer restarts', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);

    await tester.pump(const Duration(seconds: 3));
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text("WHAT'S ON"), findsOneWidget);

    // 5 s into the new scene it has not moved on yet (the old timer is gone).
    await tester.pump(const Duration(seconds: 5));
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('holding a finger down pauses the scene and letting go resumes', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);

    final finger = await tester.startGesture(middle);
    // Held far longer than a scene lasts: it does not move on.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('PLAN ANY'), findsOneWidget);

    // Letting go is not a tap, and it carries on from where it stopped.
    await finger.up();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('PLAN ANY'), findsOneWidget);

    await playScene(tester);
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('a hold on a tap zone does not count as a tap', (tester) async {
    await boot(tester, reduceMotion: false);

    final finger = await tester.startGesture(right);
    await tester.pump(const Duration(seconds: 1));
    await finger.up();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('PLAN ANY'), findsOneWidget);
  });

  testWidgets('the pause button stops the reel and play starts it again', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await playScene(tester);
    expect(find.text("WHAT'S ON"), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('the story bars and pause button sit at the top of the screen', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);

    // Regression: they once floated in the middle of the screen.
    final pause = tester.getTopLeft(find.byIcon(Icons.pause));
    expect(pause.dy, lessThan(80));
    expect(tester.view.physicalSize.height, greaterThan(400));
  });

  testWidgets('going to the background pauses the reel', (tester) async {
    await boot(tester, reduceMotion: false);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // Back in the app it is still paused, with a play button to carry on.
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('losing focus briefly does not pause the reel', (tester) async {
    await boot(tester, reduceMotion: false);

    // On the web the window losing focus (DevTools, another window) is
    // `inactive`; the reel must keep playing through it.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await playScene(tester);
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('a hidden page pauses the reel', (tester) async {
    await boot(tester, reduceMotion: false);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);
  });

  testWidgets('with a screen reader on it never moves on by itself', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false, screenReader: true);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);
    // Nothing plays, so there is nothing to pause.
    expect(find.byIcon(Icons.pause), findsNothing);

    // It still moves on by hand.
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('with reduced motion it shows still frames and no pause', (
    tester,
  ) async {
    await boot(tester);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('lays out on a small phone without overflow', (tester) async {
    await boot(tester, size: const Size(320, 568));

    for (var i = 0; i < 2; i++) {
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(300, 200));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('TICKETS AND'), findsOneWidget);
    expect(find.text('Create a free account'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
