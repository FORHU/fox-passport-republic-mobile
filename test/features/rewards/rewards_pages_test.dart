import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/presentation/pages/rewards_page.dart';
import 'package:flutter_template/features/rewards/presentation/pages/wallet_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

/// The badge for [rank], wherever it is drawn.
Finder _badge(int rank) =>
    find.byWidgetPredicate((w) => w is RankBadge && w.rank == rank);

Map<String, dynamic> _wallet({
  int coins = 1240,
  int pending = 0,
  String rank = 'Explorer',
  List<Map<String, dynamic>> history = const [],
}) =>
    {
      'success': true,
      'data': {
        'coins': coins,
        'pendingCoins': pending,
        'totalEarnedCoins': coins,
        'level': 5,
        'rank': rank,
        'history': history,
      },
    };

Map<String, dynamic> _reward(
  String id,
  String title,
  int cost, {
  double? php,
  int minLevel = 1,
  bool afford = false,
  bool level = true,
}) =>
    {
      'id': id,
      'title': title,
      'description': 'About $title',
      'coinCost': cost,
      'discountPhp': php,
      'minLevel': minLevel,
      'canAfford': afford,
      'levelQualified': level,
    };

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  Future<void> show(WidgetTester tester, Widget page) async {
    tester.view
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardsRepositoryProvider.overrideWithValue(RewardsRepository(api)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the Wallet', () {
    testWidgets('shows the balance, pending Coins and the history', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.rewardsMe)).thenAnswer(
        (_) async => _wallet(
          pending: 60,
          history: [
            {
              'id': 'g1',
              'type': 'grant',
              'action': 'attendEvent',
              'xp': 100,
              'coinsDelta': 40,
              'createdAt': '2026-11-04T10:00:00.000Z',
            },
            {
              'id': 'l1',
              'type': 'lifecycle',
              'lifecycleType': 'REDEMPTION',
              'xp': 0,
              'coinsDelta': -500,
              'createdAt': '2026-11-05T10:00:00.000Z',
            },
          ],
        ),
      );

      await show(tester, const WalletPage());

      expect(find.text('1,240'), findsOneWidget);
      expect(find.text('60 pending'), findsOneWidget);
      expect(find.text('Attend event'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);
      expect(find.text('Redeemed a reward'), findsOneWidget);
      expect(find.text('−500'), findsOneWidget);
      expect(find.text('Redeem rewards'), findsOneWidget);
    });

    testWidgets('a new person sees what Coins are and where to start', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => _wallet(coins: 0));

      await show(tester, const WalletPage());

      expect(find.text('No Coins yet'), findsOneWidget);
      expect(find.text('Find an event'), findsOneWidget);
    });

    testWidgets('a failed load says so and can be tried again', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenThrow(const NetworkException());

      await show(tester, const WalletPage());
      expect(find.text('Try again'), findsOneWidget);

      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => _wallet());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('1,240'), findsOneWidget);
    });
  });

  group('the Rewards page', () {
    setUp(() {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => _wallet(coins: 300));
      when(() => api.get(ApiEndpoints.rewardsCatalog)).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            _reward('r1', 'Small', 100, php: 20, afford: true),
            _reward('r2', 'Medium', 500, php: 100),
            _reward('r3', 'Big', 2500, php: 500, minLevel: 7, level: false),
            _reward('r4', 'Priority support', 800),
          ],
        },
      );
    });

    testWidgets('an affordable reward can be redeemed', (tester) async {
      await show(tester, const RewardsPage());

      expect(find.text('₱20 off'), findsOneWidget);
      expect(find.text('Redeem'), findsOneWidget);
    });

    testWidgets('one that is not affordable yet shows how far away', (
      tester,
    ) async {
      await show(tester, const RewardsPage());

      // 500 cost, 300 balance.
      expect(find.text('200 Coins to go'), findsOneWidget);
    });

    testWidgets('one for a higher level says when it unlocks', (tester) async {
      await show(tester, const RewardsPage());

      expect(find.text('Unlocks at Level 7'), findsOneWidget);
    });

    testWidgets('the filters split discounts from perks', (tester) async {
      await show(tester, const RewardsPage());

      await tester.tap(find.text('Perks'));
      await tester.pumpAndSettle();
      expect(find.text('Priority support'), findsOneWidget);
      expect(find.text('₱20 off'), findsNothing);

      await tester.tap(find.text('Discounts'));
      await tester.pumpAndSettle();
      expect(find.text('Priority support'), findsNothing);
      expect(find.text('₱20 off'), findsOneWidget);
    });

    testWidgets('redeeming shows the balance after, then the voucher', (
      tester,
    ) async {
      when(() => api.post(ApiEndpoints.rewardsRedeem, any())).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'success': true,
            'redemptionId': 'x',
            'coinsSpent': 100,
            'remainingCoins': 200,
            'voucher': {
              'id': 'v',
              'code': 'FOX-1234',
              'discountPhp': 20,
              'discountPercentage': null,
              'expiresAt': '2026-12-05T00:00:00.000Z',
            },
          },
        },
      );
      await show(tester, const RewardsPage());

      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      // 300 now, 100 for the reward, 200 after.
      expect(find.text('REDEEM REWARD'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('Redeem for 100 Coins'), findsOneWidget);

      await tester.tap(find.text('Redeem for 100 Coins'));
      await tester.pumpAndSettle();

      verify(() => api.post('/rewards/redeem', {'rewardId': 'r1'})).called(1);
      expect(find.text('Your voucher is ready'), findsOneWidget);
      expect(find.text('FOX-1234'), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
    });

    testWidgets('when the server refuses, the sheet stays and says why', (
      tester,
    ) async {
      when(() => api.post(ApiEndpoints.rewardsRedeem, any())).thenThrow(
        const ServerException('Not enough Coins', statusCode: 400),
      );
      await show(tester, const RewardsPage());

      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redeem for 100 Coins'));
      await tester.pumpAndSettle();

      expect(find.text('Not enough Coins'), findsOneWidget);
      expect(find.text('Redeem for 100 Coins'), findsOneWidget);
      expect(find.text('Your voucher is ready'), findsNothing);
    });
  });

  group('the Coins chip and Wallet row', () {
    testWidgets('show the balance once it is known', (tester) async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => _wallet());

      await show(
        tester,
        const Scaffold(body: Column(children: [CoinsChip(), WalletRow()])),
      );

      expect(find.text('1,240'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('1,240 Coins'), findsOneWidget);
      expect(find.text('Explorer · Level 5'), findsOneWidget);
      expect(_badge(3), findsOneWidget); // level 5 is rank 3
    });

    testWidgets('take no room when the balance cannot be had', (tester) async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenThrow(const UnauthorizedException('Sign in', statusCode: 401));

      await show(
        tester,
        const Scaffold(body: Column(children: [CoinsChip(), WalletRow()])),
      );

      expect(find.text('Wallet'), findsNothing);
      expect(tester.getSize(find.byType(CoinsChip)), Size.zero);
      expect(tester.getSize(find.byType(WalletRow)), Size.zero);
    });
  });

  group('the rank name', () {
    testWidgets('the Wallet card shows the rank and level', (tester) async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => _wallet());

      await show(tester, const WalletPage());

      expect(find.text('Explorer · Level 5'), findsOneWidget);
      expect(_badge(3), findsOneWidget);
    });

    testWidgets('nothing is shown until the server names a rank', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => _wallet(rank: ''));

      await show(tester, const WalletPage());

      expect(find.textContaining('Level'), findsNothing);
      expect(find.byType(RankBadge), findsNothing);
      expect(find.text('1,240'), findsOneWidget);
    });
  });
}
