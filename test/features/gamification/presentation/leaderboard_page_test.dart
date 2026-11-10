import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/leaderboard_labels.dart';
import 'package:flutter_template/features/gamification/presentation/pages/leaderboard_page.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FoxerBoardEntry _foxer(
  int position,
  String name, {
  LeaderboardRole role = LeaderboardRole.venue,
  String rank = 'Veteran',
  double rating = 4.8,
  int reviews = 126,
}) =>
    FoxerBoardEntry(
      position: position,
      userId: 'id-$name',
      name: name,
      role: role,
      rankName: rank,
      starRating: rating,
      reviewCount: reviews,
    );

CitizenBoardEntry _citizen(
  int position,
  String name, {
  String rank = 'Explorer',
  int level = 5,
}) =>
    CitizenBoardEntry(
      position: position,
      userId: 'id-$name',
      name: name,
      rankName: rank,
      level: level,
    );

FoxerBoard _foxerBoard(
  LeaderboardRole role,
  List<FoxerBoardEntry> rows, {
  FoxerTab tab = FoxerTab.topRated,
  FoxerBoardEntry? me,
}) =>
    FoxerBoard(tab: tab, role: role, rows: rows, me: me);

CitizenBoard _citizenBoard(
  CitizenTab tab,
  List<CitizenBoardEntry> rows, {
  CitizenBoardEntry? me,
  String? season = '2026-11',
}) =>
    CitizenBoard(tab: tab, season: season, rows: rows, me: me);

class _FakeRepository implements LeaderboardRepository {
  _FakeRepository({this.foxerAnswer, this.citizenAnswer});

  final Future<FoxerBoard> Function(
    LeaderboardRole role,
    FoxerTab tab,
    String? city,
  )? foxerAnswer;
  final Future<CitizenBoard> Function(CitizenTab tab, String? city)?
      citizenAnswer;

  final List<(LeaderboardRole, FoxerTab, String?)> foxerCalls = [];
  final List<(CitizenTab, String?)> citizenCalls = [];

  @override
  Future<FoxerBoard> foxers(
    LeaderboardRole role, {
    FoxerTab tab = FoxerTab.topRated,
    String? city,
  }) {
    foxerCalls.add((role, tab, city));
    return foxerAnswer!(role, tab, city);
  }

  @override
  Future<CitizenBoard> citizens(CitizenTab tab, {String? city}) {
    citizenCalls.add((tab, city));
    return citizenAnswer!(tab, city);
  }
}

/// The badge for [rank], wherever it is drawn.
Finder _badge(int rank) =>
    find.byWidgetPredicate((w) => w is RankBadge && w.rank == rank);

void main() {
  Future<void> show(
    WidgetTester tester,
    _FakeRepository repository, {
    LeaderboardSide side = LeaderboardSide.foxers,
    LeaderboardRole role = LeaderboardRole.venue,
    String? profileCity = 'Davao',
    String? me = 'id-Me',
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              LeaderboardPage(initialSide: side, initialRole: role),
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
          currentUserIdProvider.overrideWithValue(me),
          profileCityProvider.overrideWith((ref) async => profileCity),
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
  }

  _FakeRepository foxersOnly(
    Future<FoxerBoard> Function(
      LeaderboardRole role,
      FoxerTab tab,
      String? city,
    ) answer,
  ) =>
      _FakeRepository(foxerAnswer: answer);

  _FakeRepository citizensOnly(
    Future<CitizenBoard> Function(CitizenTab tab, String? city) answer,
  ) =>
      _FakeRepository(citizenAnswer: answer);

  group('the Foxers side', () {
    testWidgets('lists Foxers with position, rank and rating', (tester) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(role, [
          _foxer(1, 'Glass Pavilion', rank: 'Icon', rating: 4.9, reviews: 210),
          _foxer(2, 'Harbor Loft', rank: 'Headliner', reviews: 1),
          _foxer(3, 'Old Mill Hall'),
        ]),
      );
      await show(tester, repository);

      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Glass Pavilion'), findsOneWidget);
      // The rank's name, in its colour, after the role and the rank badge.
      expect(find.text('Icon'), findsOneWidget);
      expect(find.text('Headliner'), findsOneWidget);
      expect(find.text('Venue'), findsNWidgets(3));
      expect(_badge(7), findsOneWidget); // Icon is rank 7
      expect(_badge(5), findsOneWidget); // Headliner is rank 5
      // The board in words under the filters.
      expect(find.text('All cities · Venues · Top rated'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // A rating with its review count; "New" while there are too few reviews.
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('210 reviews'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.textContaining('booking'), findsNothing);
    });

    testWidgets('opens on Top rated and asks for the account role', (
      tester,
    ) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(role, [_foxer(1, 'Someone')]),
      );
      await show(tester, repository, role: LeaderboardRole.gear);

      expect(
        repository.foxerCalls.first,
        (
          LeaderboardRole.gear,
          FoxerTab.topRated,
          null,
        ),
      );
      expect(repository.citizenCalls, isEmpty);
    });

    testWidgets('switches role and tab, keeping the other', (tester) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(
          role,
          [_foxer(1, 'Someone', role: role)],
          tab: tab,
        ),
      );
      await show(tester, repository);

      await tester.tap(find.widgetWithText(BoardChip, 'Most booked'));
      await tester.pumpAndSettle();
      expect(
        repository.foxerCalls.last,
        (
          LeaderboardRole.venue,
          FoxerTab.mostBooked,
          null,
        ),
      );

      await tester.tap(find.widgetWithText(BoardChip, 'Events'));
      await tester.pumpAndSettle();
      expect(
        repository.foxerCalls.last,
        (
          LeaderboardRole.event,
          FoxerTab.mostBooked,
          null,
        ),
      );
      expect(find.text('Veteran'), findsOneWidget);
      expect(find.text('All cities · Events · Most booked'), findsOneWidget);

      await tester.tap(find.widgetWithText(BoardChip, 'Rising'));
      await tester.pumpAndSettle();
      expect(repository.foxerCalls.last.$2, FoxerTab.rising);
    });

    testWidgets('marks the caller in the list and pins them when below it', (
      tester,
    ) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(
          role,
          [_foxer(1, 'Top'), _foxer(2, 'Me')],
          me: _foxer(2, 'Me'),
        ),
      );
      await show(tester, repository);
      expect(find.text('You · Me'), findsOneWidget);

      final far = foxersOnly(
        (role, tab, city) async => _foxerBoard(
          role,
          [_foxer(1, 'Top')],
          me: _foxer(51, 'Me'),
        ),
      );
      await show(tester, far);
      expect(find.text('51'), findsOneWidget);
      expect(find.text('You · Me'), findsOneWidget);
    });

    testWidgets('says so when nobody is on the board, not a blank', (
      tester,
    ) async {
      await show(
        tester,
        foxersOnly((role, tab, city) async => _foxerBoard(role, const [])),
      );

      expect(
        find.text('No completed bookings yet this month. Check back soon.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry that asks again', (tester) async {
      var offline = true;
      final repository = foxersOnly((role, tab, city) async {
        if (offline) throw Exception('offline');
        return _foxerBoard(role, [_foxer(1, 'Back Again')]);
      });
      await show(tester, repository);

      expect(find.text('Try again'), findsOneWidget);
      final before = repository.foxerCalls.length;

      offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Back Again'), findsOneWidget);
      expect(repository.foxerCalls.length, greaterThan(before));
    });

    testWidgets('filters by the city typed in, and clears it again', (
      tester,
    ) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(role, [_foxer(1, 'Someone')]),
      );
      await show(tester, repository);

      // The caption "All cities · Venues · Top rated" opens the city sheet.
      await tester.tap(find.text('All cities · Venues · Top rated'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Davao');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(repository.foxerCalls.last.$3, 'Davao');
      expect(find.text('Davao · Venues · Top rated'), findsOneWidget);

      await tester.tap(find.text('Davao · Venues · Top rated'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'All cities').last);
      await tester.pumpAndSettle();

      expect(repository.foxerCalls.last.$3, isNull);
    });
  });

  group('the Citizens side', () {
    Future<_FakeRepository> showCitizens(
      WidgetTester tester,
      Future<CitizenBoard> Function(CitizenTab tab, String? city) answer, {
      String? profileCity = 'Davao',
    }) async {
      final repository = citizensOnly(answer);
      await show(
        tester,
        repository,
        side: LeaderboardSide.citizens,
        profileCity: profileCity,
      );
      return repository;
    }

    testWidgets('lists citizens with rank and level, and no scores', (
      tester,
    ) async {
      await showCitizens(
        tester,
        (tab, city) async => _citizenBoard(tab, [
          _citizen(1, 'Kai Santos', rank: 'Adventurer', level: 22),
          _citizen(2, 'Ana Cruz', rank: 'Adventurer', level: 20),
          _citizen(3, 'Leo Reyes', rank: 'Voyager', level: 16),
        ]),
      );

      expect(find.text('Kai Santos'), findsOneWidget);
      expect(find.text('Adventurer'), findsNWidgets(2));
      expect(find.text('Voyager'), findsOneWidget);
      expect(find.text('Lv 22'), findsOneWidget);
      expect(find.text('Lv 16'), findsOneWidget);
      expect(_badge(6), findsNWidgets(2)); // Adventurer is rank 6
      expect(_badge(5), findsOneWidget); // Voyager is rank 5
      expect(find.textContaining('XP'), findsNothing);
      // The design has no month line above the list.
      expect(find.text('November 2026'), findsNothing);
    });

    testWidgets("opens on This month and asks for the API's tab names", (
      tester,
    ) async {
      final repository = await showCitizens(
        tester,
        (tab, city) async => _citizenBoard(
          tab,
          [_citizen(1, 'Top')],
          season: tab == CitizenTab.all ? null : '2026-11',
        ),
      );

      expect(repository.citizenCalls.first, (CitizenTab.month, null));

      await tester.tap(find.widgetWithText(BoardChip, 'All time'));
      await tester.pumpAndSettle();

      expect(repository.citizenCalls.last, (CitizenTab.all, null));
      expect(find.text('November 2026'), findsNothing);
    });

    testWidgets("My city sends the caller's own profile city", (tester) async {
      final repository = await showCitizens(
        tester,
        (tab, city) async => _citizenBoard(tab, [_citizen(1, 'Local Hero')]),
        profileCity: ' Davao ',
      );

      await tester.tap(find.widgetWithText(BoardChip, 'My city'));
      await tester.pumpAndSettle();

      expect(repository.citizenCalls.last, (CitizenTab.city, 'Davao'));
      expect(find.text('Local Hero'), findsOneWidget);
      expect(find.text('Edit profile'), findsNothing);
    });

    testWidgets(
        'My city asks a caller with no city to add one, and calls nothing',
        (tester) async {
      final repository = await showCitizens(
        tester,
        (tab, city) async => _citizenBoard(tab, [_citizen(1, 'Top')]),
        profileCity: null,
      );
      final before = repository.citizenCalls.length;

      await tester.tap(find.widgetWithText(BoardChip, 'My city'));
      await tester.pumpAndSettle();

      expect(
        find.text('Add your city to your profile to see your local board.'),
        findsOneWidget,
      );
      expect(repository.citizenCalls.length, before);

      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();

      expect(find.text('edit profile opened'), findsOneWidget);
    });

    testWidgets('marks the caller by id, and pins them when below the list', (
      tester,
    ) async {
      await showCitizens(
        tester,
        (tab, city) async => _citizenBoard(
          tab,
          [_citizen(1, 'Top')],
          me: _citizen(51, 'Me'),
        ),
      );

      expect(find.text('51'), findsOneWidget);
      expect(find.text('You · Me'), findsOneWidget);
    });

    testWidgets('says so when nobody has earned XP yet, not a blank', (
      tester,
    ) async {
      await showCitizens(
        tester,
        (tab, city) async => _citizenBoard(tab, const []),
      );

      expect(
        find.text('No completed bookings yet this month. Check back soon.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry', (tester) async {
      var offline = true;
      await showCitizens(tester, (tab, city) async {
        if (offline) throw Exception('offline');
        return _citizenBoard(tab, [_citizen(1, 'Back Again')]);
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
      final repository = _FakeRepository(
        foxerAnswer: (role, tab, city) async =>
            _foxerBoard(role, [_foxer(1, 'Venue Person')]),
        citizenAnswer: (tab, city) async =>
            _citizenBoard(tab, [_citizen(1, 'Citizen One')]),
      );
      await show(tester, repository, side: LeaderboardSide.citizens);

      expect(find.text('Citizen One'), findsOneWidget);
      expect(repository.foxerCalls, isEmpty);

      await tester.tap(find.text('Foxers'));
      await tester.pumpAndSettle();

      expect(find.text('Venue Person'), findsOneWidget);
      expect(find.text('Citizen One'), findsNothing);
      expect(repository.foxerCalls.first.$1, LeaderboardRole.venue);
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
