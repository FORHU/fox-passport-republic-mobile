import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/pages/leaderboard_page.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FoxerBoardEntry _foxer(
  int position,
  String name, {
  LeaderboardRole role = LeaderboardRole.venue,
  double rating = 4.8,
  int reviews = 126,
}) =>
    FoxerBoardEntry(
      position: position,
      userId: 'id-$name',
      name: name,
      role: role,
      starRating: rating,
      reviewCount: reviews,
      paws: reviews >= 5 ? rating : null,
    );

FoxerBoard _foxerBoard(
  LeaderboardRole role,
  List<FoxerBoardEntry> rows, {
  FoxerTab tab = FoxerTab.topRated,
  FoxerBoardEntry? me,
}) =>
    FoxerBoard(tab: tab, role: role, rows: rows, me: me);

class _FakeRepository implements LeaderboardRepository {
  _FakeRepository({this.foxerAnswer});

  final Future<FoxerBoard> Function(
    LeaderboardRole role,
    FoxerTab tab,
    String? city,
  )? foxerAnswer;

  final List<(LeaderboardRole, FoxerTab, String?)> foxerCalls = [];

  @override
  Future<FoxerBoard> foxers(
    LeaderboardRole role, {
    FoxerTab tab = FoxerTab.topRated,
    String? city,
  }) {
    foxerCalls.add((role, tab, city));
    return foxerAnswer!(role, tab, city);
  }
}

void main() {
  Future<void> show(
    WidgetTester tester,
    _FakeRepository repository, {
    LeaderboardRole role = LeaderboardRole.venue,
    String? profileCity = 'Davao',
    String? me = 'id-Me',
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => LeaderboardPage(initialRole: role),
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

  group('the Foxers side', () {
    testWidgets('lists Foxers with position, role and rating', (tester) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(role, [
          _foxer(1, 'Glass Pavilion', rating: 4.9, reviews: 210),
          _foxer(2, 'Harbor Loft', reviews: 1),
          _foxer(3, 'Old Mill Hall'),
        ]),
      );
      await show(tester, repository);

      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Glass Pavilion'), findsOneWidget);
      // No rank or level: those are retired.
      expect(find.textContaining('Level'), findsNothing);
      expect(find.text('Venue'), findsNWidgets(3));
      // The board in words under the filters.
      expect(find.text('All cities · Venues · Top rated'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // A rating with its review count; "New" while there are too few reviews.
      expect(find.text('4.9 · 210'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      // No booking counts on the rows (the ranking note may say the word).
      expect(find.textContaining(RegExp(r'\d+ bookings?')), findsNothing);
    });

    testWidgets('opens on Top rated and asks for the account role', (
      tester,
    ) async {
      final repository = foxersOnly(
        (role, tab, city) async => _foxerBoard(role, [_foxer(1, 'Someone')]),
      );
      await show(tester, repository, role: LeaderboardRole.providers);

      expect(
        repository.foxerCalls.first,
        (
          LeaderboardRole.providers,
          FoxerTab.topRated,
          null,
        ),
      );
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
      // Pinned above the list, as in the design, and the ranking note ends it.
      expect(
        tester.getTopLeft(find.text('You · Me')).dy,
        lessThan(tester.getTopLeft(find.text('Top')).dy),
      );
      expect(find.textContaining('Top rated ranks by Paws'), findsOneWidget);
      expect(find.textContaining('no Citizens leaderboard'), findsOneWidget);
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
}
