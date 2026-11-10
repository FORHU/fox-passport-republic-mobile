import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/pages/leaderboard_page.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/presentation/pages/rewards_page.dart';
import 'package:flutter_template/features/rewards/presentation/pages/wallet_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Board implements LeaderboardRepository {
  @override
  Future<FoxerBoard> foxers(
    LeaderboardRole role, {
    FoxerTab tab = FoxerTab.topRated,
    String? city,
  }) async =>
      FoxerBoard(
        tab: tab,
        role: role,
        rows: [
          for (var i = 1; i <= 6; i++)
            FoxerBoardEntry(
              position: i,
              userId: 'id-$i',
              name: 'A very long venue name that goes on and on $i',
              role: role,
              rankName: 'Grand Master',
              starRating: 4.8,
              reviewCount: 12345,
            ),
        ],
      );

  @override
  Future<CitizenBoard> citizens(CitizenTab tab, {String? city}) async =>
      CitizenBoard(
        tab: tab,
        season: '2026-11',
        rows: [
          for (var i = 1; i <= 6; i++)
            CitizenBoardEntry(
              position: i,
              userId: 'id-$i',
              name: 'Maria Cristina de la Santisima Trinidad $i',
              rankName: 'Grand Master',
              level: 50,
            ),
        ],
      );
}

const _sizes = [Size(320, 640), Size(360, 740)];
const _scales = [1.0, 1.5, 2.0];

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(() => api.get(ApiEndpoints.rewardsMe)).thenAnswer(
      (_) async => {
        'success': true,
        'data': {
          'coins': 1234567,
          'pendingCoins': 98765,
          'totalEarnedCoins': 2000000,
          'level': 50,
          'rank': 'Grand Master',
          'history': [
            for (var i = 0; i < 6; i++)
              {
                'id': 'g$i',
                'type': 'grant',
                'action': 'attendEvent',
                'xp': 100,
                'coinsDelta': 40,
                'createdAt': '2026-11-0${i + 1}T10:00:00.000Z',
              },
          ],
        },
      },
    );
    when(() => api.get(ApiEndpoints.rewardsCatalog)).thenAnswer(
      (_) async => {
        'success': true,
        'data': [
          for (var i = 0; i < 5; i++)
            {
              'id': 'r$i',
              'title': 'A reward with a rather long title number $i',
              'description':
                  'A longer description that explains what this reward does '
                      'and when it can be used, so it wraps on a small phone.',
              'coinCost': 250000,
              'discountPhp': 500.0,
              'minLevel': 40,
              'canAfford': i.isEven,
              'levelQualified': i.isEven,
            },
        ],
      },
    );
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page,
    Size size,
    double scale,
  ) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardsRepositoryProvider.overrideWithValue(RewardsRepository(api)),
          leaderboardRepositoryProvider.overrideWithValue(_Board()),
          currentUserIdProvider.overrideWithValue('id-me'),
          profileCityProvider.overrideWith((ref) async => 'Davao'),
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

  final pages = <String, Widget>{
    'Wallet': const WalletPage(),
    'Rewards': const RewardsPage(),
    'Leaderboard (Foxers)': const LeaderboardPage(
      initialSide: LeaderboardSide.foxers,
      initialRole: LeaderboardRole.venue,
    ),
    'Leaderboard (Citizens)': const LeaderboardPage(
      initialSide: LeaderboardSide.citizens,
      initialRole: LeaderboardRole.venue,
    ),
  };

  for (final entry in pages.entries) {
    for (final size in _sizes) {
      for (final scale in _scales) {
        testWidgets(
          '${entry.key} fits ${size.width.toInt()} px, text x$scale',
          (tester) async {
            await pumpPage(tester, entry.value, size, scale);

            final error = tester.takeException();
            if (error is FlutterError) fail(error.toStringDeep());
            expect(error, isNull);
          },
        );
      }
    }
  }
}
