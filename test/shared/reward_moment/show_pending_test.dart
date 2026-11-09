import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/reward_moment/reward_moments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t0 = DateTime.utc(2026, 11, 9, 10);

WalletEntry _grant(String id, String action, int xp, int coins, int minutes) =>
    WalletEntry(
      id: id,
      isGrant: true,
      action: action,
      xp: xp,
      coinsDelta: coins,
      createdAt: _t0.add(Duration(minutes: minutes)),
    );

WalletSummary _wallet({
  required int level,
  required String rank,
  List<WalletEntry> history = const [],
}) =>
    WalletSummary(
      coins: 100,
      pendingCoins: 0,
      totalEarnedCoins: 100,
      level: level,
      rank: rank,
      history: history,
    );

const _passport = PassportSummary(
  level: 5,
  totalXp: 1000,
  levelStartXp: 800,
  nextLevelXp: 1370,
  stamps: [],
  badges: [],
);

void main() {
  late SharedPreferences prefs;
  late WalletSummary wallet;
  late GoRouter router;
  String? passportTab;

  setUp(() async {
    resetRewardMomentGuard();
    passportTab = null;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = _wallet(level: 5, rank: 'Explorer');
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showPendingRewardMoments(context, ref),
              child: const Text('check'),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.passport,
          builder: (_, state) {
            passportTab = state.uri.queryParameters['tab'];
            return const Text('passport screen');
          },
        ),
        GoRoute(
          path: RouteNames.howItWorks,
          builder: (_, __) => const Text('how it works screen'),
        ),
      ],
    );
  });

  Future<void> check(WidgetTester tester) async {
    await tester.tap(find.text('check'));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester, {String? userId = 'u1'}) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue(userId),
          walletProvider.overrideWith((ref) async => wallet),
          passportProvider.overrideWith((ref) async => _passport),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the first look shows nothing and remembers what is there',
      (tester) async {
    wallet = _wallet(
      level: 5,
      rank: 'Explorer',
      history: [_grant('a', 'attend_event', 100, 40, -30)],
    );
    await start(tester);

    await check(tester);

    expect(find.textContaining('attended'), findsNothing);
    expect(prefs.getString(rewardSeenAtKey('u1')), isNotNull);
    expect(prefs.getInt(rewardSeenRankKey('u1')), 3);
  });

  testWidgets('a grant after the last look is shown once', (tester) async {
    await prefs.setString(
      rewardSeenAtKey('u1'),
      _t0.toIso8601String(),
    );
    await prefs.setInt(rewardSeenRankKey('u1'), 3);
    wallet = _wallet(
      level: 5,
      rank: 'Explorer',
      history: [_grant('a', 'attend_event', 100, 40, 5)],
    );
    await start(tester);

    await check(tester);
    expect(find.text('You attended an event'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('You attended an event'), findsNothing);

    // Remembered: asking again shows nothing.
    await check(tester);
    expect(find.text('You attended an event'), findsNothing);
    expect(
      DateTime.parse(prefs.getString(rewardSeenAtKey('u1'))!),
      _t0.add(const Duration(minutes: 5)),
    );
  });

  testWidgets('a new rank shows the rank-up sheet after the reward sheet',
      (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    await prefs.setInt(rewardSeenRankKey('u1'), 5);
    wallet = _wallet(
      level: 20,
      rank: 'Adventurer',
      history: [
        _grant('a', 'attend_event', 100, 40, 5),
        _grant('r', 'rank_up', 0, 500, 5),
      ],
    );
    await start(tester);

    await check(tester);
    expect(find.text('You attended an event'), findsOneWidget);
    // The rank-up Coins are announced on the rank-up sheet, not twice.
    expect(find.text('+40'), findsOneWidget);
    expect(find.text('+500'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('NEW RANK'), findsOneWidget);
    expect(find.text('Adventurer'), findsOneWidget);
    expect(find.text('+500 Coins'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(prefs.getInt(rewardSeenRankKey('u1')), 6);
    await check(tester);
    expect(find.text('NEW RANK'), findsNothing);
  });

  testWidgets('View my passport opens the Passport', (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    await prefs.setInt(rewardSeenRankKey('u1'), 3);
    wallet = _wallet(
      level: 5,
      rank: 'Explorer',
      history: [_grant('a', 'attend_event', 100, 40, 5)],
    );
    await start(tester);

    await check(tester);
    await tester.tap(find.text('View my passport'));
    await tester.pumpAndSettle();

    expect(find.text('passport screen'), findsOneWidget);
    expect(passportTab, isNull);
  });

  testWidgets('See my badges on the rank-up sheet opens the Badges tab',
      (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    await prefs.setInt(rewardSeenRankKey('u1'), 5);
    wallet = _wallet(level: 20, rank: 'Adventurer');
    await start(tester);

    await check(tester);
    await tester.tap(find.text('See my badges'));
    await tester.pumpAndSettle();

    expect(find.text('passport screen'), findsOneWidget);
    expect(passportTab, 'badges');
  });

  testWidgets('Learn more opens how XP and Coins work', (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    await prefs.setInt(rewardSeenRankKey('u1'), 3);
    wallet = _wallet(
      level: 5,
      rank: 'Explorer',
      history: [_grant('a', 'attend_event', 100, 40, 5)],
    );
    await start(tester);

    await check(tester);
    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();

    expect(find.text('how it works screen'), findsOneWidget);
  });

  testWidgets('nobody signed in: nothing is asked or shown', (tester) async {
    await start(tester, userId: null);

    await check(tester);

    expect(prefs.getKeys(), isEmpty);
  });

  testWidgets('a wallet that cannot be loaded is skipped quietly',
      (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    await prefs.setInt(rewardSeenRankKey('u1'), 3);
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserIdProvider.overrideWithValue('u1'),
          walletProvider.overrideWith((ref) async => throw Exception('down')),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await check(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('NEW RANK'), findsNothing);
    // Nothing was marked as seen, so the next check tries again.
    expect(prefs.getInt(rewardSeenRankKey('u1')), 3);
  });
}
