import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/reward_moment/reward_moments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t0 = DateTime.utc(2026, 11, 9, 10);

WalletEntry _grant(String id, String action, int coins, int minutes) =>
    WalletEntry(
      id: id,
      isGrant: true,
      action: action,
      coinsDelta: coins,
      createdAt: _t0.add(Duration(minutes: minutes)),
    );

WalletSummary _wallet({List<WalletEntry> history = const []}) => WalletSummary(
      coins: 100,
      pendingCoins: 0,
      totalEarnedCoins: 100,
      history: history,
    );

void main() {
  late SharedPreferences prefs;
  late WalletSummary wallet;
  late GoRouter router;

  setUp(() async {
    resetRewardMomentGuard();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    wallet = _wallet();
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
          builder: (_, __) => const Text('passport screen'),
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
    wallet = _wallet(history: [_grant('a', 'attend_event', 40, -30)]);
    await start(tester);

    await check(tester);

    expect(find.textContaining('attended'), findsNothing);
    expect(prefs.getString(rewardSeenAtKey('u1')), isNotNull);
  });

  testWidgets('a grant after the last look is shown once', (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    wallet = _wallet(history: [_grant('a', 'attend_event', 40, 5)]);
    await start(tester);

    await check(tester);
    expect(find.text('You attended an event'), findsOneWidget);
    expect(find.text('+40'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);

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

  testWidgets('View my passport opens the Passport', (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    wallet = _wallet(history: [_grant('a', 'attend_event', 40, 5)]);
    await start(tester);

    await check(tester);
    await tester.tap(find.text('View my passport'));
    await tester.pumpAndSettle();

    expect(find.text('passport screen'), findsOneWidget);
  });

  testWidgets('Learn more opens how Tokens work', (tester) async {
    await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    wallet = _wallet(history: [_grant('a', 'attend_event', 40, 5)]);
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
    // Nothing was marked as seen, so the next check tries again.
    expect(
      prefs.getString(rewardSeenAtKey('u1')),
      _t0.toIso8601String(),
    );
  });
}
