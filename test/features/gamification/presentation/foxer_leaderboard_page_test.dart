import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/pages/foxer_leaderboard_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

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
  _FakeRepository(this.answer);

  final Future<FoxerBoard> Function(LeaderboardRole role, String? city) answer;
  final List<(LeaderboardRole, String?)> calls = [];

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
  }) async {
    final repository = _FakeRepository(answer);
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
          home: FoxerLeaderboardPage(initialRole: role),
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

  test('a month reads as words, and nothing when it does not parse', () {
    const locale = Locale('en');
    expect(monthLabel('2026-11', locale), 'November 2026');
    expect(monthLabel('2026-13', locale), '');
    expect(monthLabel('nope', locale), '');
    expect(monthLabel('', locale), '');
    expect(monthLabel(null, locale), '');
  });
}
