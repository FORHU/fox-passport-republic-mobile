import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/leaderboard_labels.dart';
import 'package:flutter_template/features/gamification/presentation/pages/leaderboard_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FoxerBoardEntry _entry(
  int position,
  String name, {
  LeaderboardRole role = LeaderboardRole.venue,
  String rank = 'Veteran',
  bool isMe = false,
}) =>
    FoxerBoardEntry(
      position: position,
      userId: 'id-$name',
      name: name,
      role: role,
      rankName: rank,
      isMe: isMe,
    );

class _FakeRepository implements LeaderboardRepository {
  _FakeRepository(this.answer, {this.citizenAnswer});

  final Future<FoxerBoard> Function(LeaderboardRole role, String? city) answer;
  final Future<CitizenBoard> Function(CitizenTab tab)? citizenAnswer;
  final List<(LeaderboardRole, String?)> calls = [];
  final List<CitizenTab> citizenCalls = [];

  @override
  Future<CitizenBoard> citizens(CitizenTab tab) {
    citizenCalls.add(tab);
    return citizenAnswer!(tab);
  }

  @override
  Future<FoxerBoard> foxers(LeaderboardRole role, {String? city}) {
    calls.add((role, city));
    return answer(role, city);
  }
}

void main() {
  Future<_FakeRepository> show(
    WidgetTester tester,
    Future<FoxerBoard> Function(LeaderboardRole role, String? city) answer, {
    LeaderboardRole role = LeaderboardRole.venue,
    LeaderboardSide side = LeaderboardSide.foxers,
    Future<CitizenBoard> Function(CitizenTab tab)? citizens,
  }) async {
    final repository = _FakeRepository(answer, citizenAnswer: citizens);
    tester.view
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LeaderboardPage(initialSide: side, initialRole: role),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  FoxerBoard board(
    LeaderboardRole role,
    List<FoxerBoardEntry> rows, {
    FoxerBoardEntry? me,
    String? city,
  }) =>
      FoxerBoard(
        role: role,
        city: city,
        month: '2026-11',
        rows: rows,
        me: me,
      );

  testWidgets('lists the Foxers with position, rank and the month', (
    tester,
  ) async {
    await show(
      tester,
      (role, city) async => board(role, [
        _entry(1, 'Glass Pavilion', rank: 'Icon'),
        _entry(1, 'Harbor Loft', rank: 'Headliner'),
        _entry(3, 'Old Mill Hall'),
      ]),
    );

    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.textContaining('Most booked'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.text('Glass Pavilion'), findsOneWidget);
    expect(find.text('Venues · Icon'), findsOneWidget);
    expect(find.text('Venues · Headliner'), findsOneWidget);
    expect(find.text('Venues · Veteran'), findsOneWidget);
    // Ties share a position.
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('marks the caller inside the list', (tester) async {
    final mine = _entry(2, 'Me Myself', isMe: true);
    await show(
      tester,
      (role, city) async => board(
        role,
        [_entry(1, 'Top'), mine],
        me: mine,
      ),
    );

    expect(find.text('You'), findsOneWidget);
    expect(find.text('Me Myself'), findsOneWidget);
  });

  testWidgets('pins the caller below the list when it does not reach them', (
    tester,
  ) async {
    await show(
      tester,
      (role, city) async => board(
        role,
        [_entry(1, 'Top')],
        me: _entry(27, 'Far Down', isMe: true),
      ),
    );

    expect(find.text('Far Down'), findsOneWidget);
    expect(find.text('27'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('says so when nobody has completed a booking, not a blank', (
    tester,
  ) async {
    await show(tester, (role, city) async => board(role, const []));

    expect(
      find.text('No completed bookings yet this month. Check back soon.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load offers a retry that asks again', (tester) async {
    // The provider also retries by itself, so the fake keeps failing until the
    // test lets it recover; only then does the tap have something to fix.
    var offline = true;
    final repository = await show(tester, (role, city) async {
      if (offline) throw Exception('offline');
      return board(role, [_entry(1, 'Back Again')]);
    });

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Back Again'), findsNothing);
    final before = repository.calls.length;

    offline = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Back Again'), findsOneWidget);
    expect(repository.calls.length, greaterThan(before));
  });

  testWidgets('opens on the role it was given and switches on a tap', (
    tester,
  ) async {
    final repository = await show(
      tester,
      (role, city) async => board(
        role,
        [_entry(1, 'Someone', role: role)],
      ),
      role: LeaderboardRole.gear,
    );

    expect(repository.calls.first.$1, LeaderboardRole.gear);
    expect(find.text('Gear · Veteran'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Events'));
    await tester.pumpAndSettle();

    expect(repository.calls.last.$1, LeaderboardRole.event);
    expect(find.text('Events · Veteran'), findsOneWidget);
  });

  testWidgets('filters by the city typed in, and clears it again', (
    tester,
  ) async {
    final repository = await show(
      tester,
      (role, city) async => board(role, [_entry(1, 'Someone')], city: city),
    );

    expect(find.text('All cities'), findsOneWidget);

    await tester.tap(find.text('All cities'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Davao');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.calls.last, (LeaderboardRole.venue, 'Davao'));
    expect(find.text('Davao'), findsOneWidget);

    await tester.tap(find.text('Davao'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'All cities').last);
    await tester.pumpAndSettle();

    expect(repository.calls.last, (LeaderboardRole.venue, null));
  });

  CitizenBoardEntry citizen(
    int position,
    String name, {
    String rank = 'Explorer',
    int level = 5,
    bool isMe = false,
  }) =>
      CitizenBoardEntry(
        position: position,
        userId: 'id-$name',
        name: name,
        rankName: rank,
        level: level,
        isMe: isMe,
      );

  CitizenBoard citizenBoard(
    CitizenTab tab,
    List<CitizenBoardEntry> rows, {
    CitizenBoardEntry? me,
    String? city,
    String? month = '2026-11',
  }) =>
      CitizenBoard(tab: tab, city: city, month: month, rows: rows, me: me);

  Future<_FakeRepository> showCitizens(
    WidgetTester tester,
    Future<CitizenBoard> Function(CitizenTab tab) answer,
  ) =>
      show(
        tester,
        (role, city) async => board(role, const []),
        side: LeaderboardSide.citizens,
        citizens: answer,
      );

  group('the Citizens side', () {
    testWidgets('lists citizens with rank and level, and no scores', (
      tester,
    ) async {
      await showCitizens(
        tester,
        (tab) async => citizenBoard(tab, [
          citizen(1, 'Kai Santos', rank: 'Adventurer', level: 22),
          citizen(1, 'Ana Cruz', rank: 'Adventurer', level: 20),
          citizen(3, 'Leo Reyes', rank: 'Voyager', level: 16),
        ]),
      );

      expect(find.text('Kai Santos'), findsOneWidget);
      expect(find.text('Adventurer · Level 22'), findsOneWidget);
      expect(find.text('Voyager · Level 16'), findsOneWidget);
      // Ties share a position.
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
      expect(find.textContaining('XP'), findsNothing);
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('opens on This month and switches tabs', (tester) async {
      final repository = await showCitizens(
        tester,
        (tab) async => citizenBoard(
          tab,
          [citizen(1, 'Top')],
          month: tab == CitizenTab.all ? null : '2026-11',
        ),
      );

      expect(repository.citizenCalls.first, CitizenTab.month);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All time'));
      await tester.pumpAndSettle();

      expect(repository.citizenCalls.last, CitizenTab.all);
      // All time does not belong to a month.
      expect(find.text('November 2026'), findsNothing);
    });

    testWidgets('pins the caller below the list and marks them in it', (
      tester,
    ) async {
      await showCitizens(
        tester,
        (tab) async => citizenBoard(
          tab,
          [citizen(1, 'Top')],
          me: citizen(48, 'Far Down', isMe: true),
        ),
      );

      expect(find.text('Far Down'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('says so when nobody has earned XP yet, not a blank', (
      tester,
    ) async {
      await showCitizens(tester, (tab) async => citizenBoard(tab, const []));

      expect(
        find.text('No completed bookings yet this month. Check back soon.'),
        findsOneWidget,
      );
    });

    testWidgets('asks a caller with no city to add one, and opens Edit profile',
        (
      tester,
    ) async {
      final repository = _FakeRepository(
        (role, city) async => board(role, const []),
        citizenAnswer: (tab) async => citizenBoard(tab, const []),
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LeaderboardPage(
              initialSide: LeaderboardSide.citizens,
              initialRole: LeaderboardRole.event,
            ),
          ),
          GoRoute(
            path: RouteNames.profileEdit,
            builder: (context, state) =>
                const Scaffold(body: Text('edit profile opened')),
          ),
        ],
      );
      tester.view
        ..physicalSize = const Size(900, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaderboardRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'My city'));
      await tester.pumpAndSettle();

      expect(
        find.text('Add your city to your profile to see your local board.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      expect(find.text('edit profile opened'), findsOneWidget);
    });

    testWidgets('My city shows the board once the caller has a city', (
      tester,
    ) async {
      await showCitizens(
        tester,
        (tab) async => citizenBoard(
          tab,
          [citizen(1, 'Local Hero')],
          city: tab == CitizenTab.city ? 'Davao' : null,
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'My city'));
      await tester.pumpAndSettle();

      expect(find.text('Local Hero'), findsOneWidget);
      expect(find.textContaining('Davao'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      var offline = true;
      await showCitizens(tester, (tab) async {
        if (offline) throw Exception('offline');
        return citizenBoard(tab, [citizen(1, 'Back Again')]);
      });

      expect(find.text('Try again'), findsOneWidget);

      offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Back Again'), findsOneWidget);
    });
  });

  group('the switch', () {
    testWidgets('moves between the Citizens and Foxers sides', (tester) async {
      final repository = await show(
        tester,
        (role, city) async => board(role, [_entry(1, 'Venue Person')]),
        side: LeaderboardSide.citizens,
        citizens: (tab) async => citizenBoard(tab, [citizen(1, 'Citizen One')]),
      );

      expect(find.text('Citizen One'), findsOneWidget);
      expect(repository.calls, isEmpty);

      await tester.tap(find.text('Foxers'));
      await tester.pumpAndSettle();

      expect(find.text('Venue Person'), findsOneWidget);
      expect(find.text('Citizen One'), findsNothing);
      expect(repository.calls.first.$1, LeaderboardRole.venue);
    });

    testWidgets('the Foxers side is the default', (tester) async {
      final repository = await show(
        tester,
        (role, city) async => board(role, [_entry(1, 'Someone')]),
      );

      expect(repository.citizenCalls, isEmpty);
      expect(find.text('Someone'), findsOneWidget);
    });
  });

  test('a month reads as words, and nothing when it does not parse', () {
    const locale = Locale('en');
    expect(monthLabel('2026-11', locale), 'November 2026');
    expect(monthLabel('2026-13', locale), '');
    expect(monthLabel('nope', locale), '');
    expect(monthLabel('', locale), '');
    expect(monthLabel(null, locale), '');
  });
}
