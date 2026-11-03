import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/welcome/presentation/widgets/reel_scenes.dart';
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

    await tester.tapAt(left);
    await tester.pumpAndSettle();
    expect(find.text("WHAT'S ON"), findsOneWidget);

    // On from the last scene starts again; back from the first stays put.
    await tester.tapAt(middle);
    await tester.pumpAndSettle();
    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text('PLAN ANY'), findsOneWidget);

    await tester.tapAt(left);
    await tester.pumpAndSettle();
    expect(find.text('PLAN ANY'), findsOneWidget);
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

    // 1 · plan any occasion: what you would hold for each occasion.
    expect(
      find.text(
        'Weddings, birthdays, corporate nights and nights out: book the '
        'venue, the gear and the crew in one app.',
      ),
      findsOneWidget,
    );
    for (final text in [
      'KAI TURNS',
      '30',
      "FOXCON '26",
      'SPEAKER',
      'Rae Cruz',
      'LISBON',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('Ana\n& Leo', findRichText: true), findsOneWidget);

    // 2 · what's on near you: a board of cities around the world.
    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(
      find.text(
        'Tokyo, Paris, New York or your own city: events this week and '
        'venues free on your date, wherever you are.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reel-board')), findsOneWidget);
    for (final text in ['CITY', 'EVENT', 'STATUS', 'LIVE', 'FEW LEFT']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('Every Foxer is verified'), findsOneWidget);

    // 3 · tickets and stamps: a thermal ticket over a stamped passport page.
    await tester.tapAt(right);
    await tester.pumpAndSettle();
    expect(find.text('YOUR PASSPORT'), findsOneWidget);
    for (final text in [
      'VISAS · STAMPS',
      'GARDEN WEDDING',
      'Sun 15 Nov · 16:00 · Lisbon',
      'WORKS OFFLINE',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  group('the board', () {
    ReelBoardRow row(String city) =>
        (city: city, event: 'Event $city', status: ReelBoardStatus.tonight);
    final start = [
      for (final c in ['A', 'B', 'C', 'D', 'E']) row(c),
    ];
    final feed = [
      for (final c in ['F', 'G', 'H', 'I', 'J']) row(c),
    ];
    List<String> cities(List<ReelBoardRow> rows) =>
        [for (final r in rows) r.city];

    test('starts on its first rows, the first one about to turn', () {
      final board = ReelBoard.at(0, start, feed);
      expect(cities(board.before), ['A', 'B', 'C', 'D', 'E']);
      expect(board.flipping, 0);
      expect(board.into, 0);
    });

    test('turns the rows over one at a time, across the board', () {
      // Halfway through the fifth step every row has turned over, in the
      // order 0, 2, 4, 1, 3.
      final board = ReelBoard.at(4.5 / ReelBoard.steps, start, feed);
      expect(cities(board.rows), ['F', 'I', 'G', 'J', 'H']);
      expect(board.flipping, 3);
    });

    test('turns them back, so the loop ends where it began', () {
      final board = ReelBoard.at(0.999, start, feed);
      expect(cities(board.rows), ['A', 'B', 'C', 'D', 'E']);
    });

    test('each letter flips a little after the one before it', () {
      expect(ReelBoard.flipOf(0, 0), 0);
      expect(
        ReelBoard.flipOf(0.05, 0),
        greaterThan(ReelBoard.flipOf(0.05, 5)),
      );
      // The whole row has turned well before the next step.
      expect(ReelBoard.flipOf(0.5, ReelBoard.cityCells + 10), 1);
    });
  });

  testWidgets('the board turns over while it plays and holds under a finger', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 700));

    // Everything printed on the board but its clock.
    String board() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('reel-board')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data ?? '')
        .where((text) => !text.startsWith('LOCAL'))
        .join();

    final first = board();
    await tester.pump(const Duration(seconds: 3));
    expect(board(), isNot(first));

    final finger = await tester.startGesture(middle);
    await tester.pump(const Duration(milliseconds: 300));
    final held = board();
    await tester.pump(const Duration(seconds: 5));
    expect(board(), held);
    await finger.up();
  });

  testWidgets('the pile of things scales up to fill a tall phone', (
    tester,
  ) async {
    await boot(tester, size: const Size(400, 850));

    // The pile is drawn 304 wide; on a 400-wide phone it should be a good
    // deal wider, not left small in the middle of an empty stage.
    final pile = tester.getRect(find.byKey(const ValueKey('reel-occasions')));
    expect(pile.width, greaterThan(330));
    expect(pile.width, lessThanOrEqualTo(440));
    expect(tester.takeException(), isNull);
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

  testWidgets('plays on its own and starts again after the last scene', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);
    expect(find.text('PLAN ANY'), findsOneWidget);

    for (final headline in ["WHAT'S ON", 'TICKETS AND']) {
      await playScene(tester);
      expect(find.text(headline), findsOneWidget);
    }

    // It loops: after the last scene comes the first, and on it goes.
    await playScene(tester);
    expect(find.text('PLAN ANY'), findsOneWidget);
    await playScene(tester);
    expect(find.text("WHAT'S ON"), findsOneWidget);
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

  testWidgets('the story bars sit at the top, with no pause button', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);

    // Regression: they once floated in the middle of the screen.
    final bars = find.byType(FractionallySizedBox);
    expect(bars, findsNWidgets(3));
    expect(tester.getTopLeft(bars.first).dy, lessThan(80));
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(tester.view.physicalSize.height, greaterThan(400));
  });

  testWidgets('going to the background pauses the reel until it is back', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);

    // Back in the app it carries on by itself; there is no play button.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await playScene(tester);
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('losing focus briefly does not pause the reel', (tester) async {
    await boot(tester, reduceMotion: false);

    // On the web the window losing focus (DevTools, another window) is
    // `inactive`; the reel must keep playing through it.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await playScene(tester);
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('a hidden page pauses the reel', (tester) async {
    await boot(tester, reduceMotion: false);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);
  });

  testWidgets('with a screen reader on it never moves on by itself', (
    tester,
  ) async {
    await boot(tester, reduceMotion: false, screenReader: true);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);

    // It still moves on by hand.
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text("WHAT'S ON"), findsOneWidget);
  });

  testWidgets('with reduced motion it shows still frames', (
    tester,
  ) async {
    await boot(tester);

    await tester.pump(const Duration(seconds: 20));
    expect(find.text('PLAN ANY'), findsOneWidget);
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
