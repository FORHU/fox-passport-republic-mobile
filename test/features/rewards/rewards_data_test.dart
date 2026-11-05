import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/features/rewards/presentation/widgets/wallet_entry_title.dart';
import 'package:flutter_template/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _walletJson() => {
      'coins': 1240,
      'pendingCoins': 60,
      'totalEarnedCoins': 2000,
      'level': 5,
      'rank': 'Explorer',
      'history': [
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
    };

void main() {
  group('the wallet', () {
    test('reads the balance, pending Coins, level, rank and history', () {
      final wallet = WalletSummary.fromJson(_walletJson());

      expect(wallet.coins, 1240);
      expect(wallet.pendingCoins, 60);
      expect(wallet.totalEarnedCoins, 2000);
      expect(wallet.level, 5);
      expect(wallet.rank, 'Explorer');
      expect(wallet.history, hasLength(2));
      expect(wallet.history.first.isGrant, isTrue);
      expect(wallet.history.last.isGrant, isFalse);
      expect(wallet.history.last.coinsDelta, -500);
      expect(wallet.isEmpty, isFalse);
    });

    test('an empty answer is an empty wallet, not an error', () {
      final wallet = WalletSummary.fromJson(const {});

      expect(wallet.coins, 0);
      expect(wallet.level, 1);
      expect(wallet.history, isEmpty);
      expect(wallet.isEmpty, isTrue);
    });
  });

  group('history titles', () {
    final l10n = AppLocalizationsEn();
    WalletEntry entry({String? action, String? life, bool grant = true}) =>
        WalletEntry(
          id: 'x',
          isGrant: grant,
          action: action,
          lifecycleType: life,
          xp: 0,
          coinsDelta: 0,
          createdAt: DateTime(2026),
        );

    test('a grant is its action in words', () {
      expect(
        walletEntryTitle(l10n, entry(action: 'attendEvent')),
        'Attend event',
      );
      expect(
        walletEntryTitle(l10n, entry(action: 'leave_review')),
        'Leave review',
      );
    });

    test('a change is named by what happened', () {
      for (final (life, text) in [
        ('RELEASE', 'Coins released'),
        ('REDEMPTION', 'Redeemed a reward'),
        ('EXPIRY', 'Coins expired'),
        ('REVERSAL', 'Coins reversed'),
      ]) {
        expect(
          walletEntryTitle(l10n, entry(life: life, grant: false)),
          text,
        );
      }
    });

    test('with nothing to go on it says Coins', () {
      expect(walletEntryTitle(l10n, entry()), 'Coins');
    });
  });

  group('the repository', () {
    late _MockApi api;
    late RewardsRepository repo;

    setUp(() {
      api = _MockApi();
      repo = RewardsRepository(api);
    });

    test('loads the wallet from /rewards/me', () async {
      when(() => api.get(ApiEndpoints.rewardsMe)).thenAnswer(
        (_) async => {'success': true, 'data': _walletJson()},
      );

      final wallet = await repo.wallet();

      expect(wallet.coins, 1240);
      verify(() => api.get('/rewards/me')).called(1);
    });

    test('asks for one XP path when told which', () async {
      when(
        () => api.get(ApiEndpoints.rewardsMe, query: {'path': 'gearFoxer'}),
      ).thenAnswer((_) async => {'success': true, 'data': _walletJson()});

      final wallet = await repo.wallet(path: 'gearFoxer');

      expect(wallet.rank, 'Explorer');
      verify(
        () => api.get('/rewards/me', query: {'path': 'gearFoxer'}),
      ).called(1);
    });

    test('a wallet answer without data is an error', () async {
      when(() => api.get(ApiEndpoints.rewardsMe))
          .thenAnswer((_) async => {'success': true});

      expect(repo.wallet(), throwsFormatException);
    });

    test('loads the catalogue and its flags from /rewards/catalog', () async {
      when(() => api.get(ApiEndpoints.rewardsCatalog)).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'id': 'r1',
              'title': 'Off a booking',
              'coinCost': 100,
              'discountPhp': 20,
              'minLevel': 1,
              'canAfford': true,
              'levelQualified': true,
            },
            {
              'id': 'r2',
              'title': 'Priority support',
              'coinCost': 800,
              'minLevel': 7,
              'canAfford': false,
              'levelQualified': false,
            },
          ],
        },
      );

      final items = await repo.catalog();

      expect(items, hasLength(2));
      expect(items.first.isDiscount, isTrue);
      expect(items.first.discountPhp, 20);
      expect(items.first.canAfford, isTrue);
      expect(items.last.isDiscount, isFalse);
      expect(items.last.levelQualified, isFalse);
      expect(items.last.minLevel, 7);
    });

    test('redeeming sends the reward id and returns the voucher', () async {
      when(() => api.post(ApiEndpoints.rewardsRedeem, any())).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'success': true,
            'redemptionId': 'x',
            'coinsSpent': 500,
            'remainingCoins': 740,
            'voucher': {
              'id': 'v',
              'code': 'FOX-1234',
              'discountPhp': 100,
              'discountPercentage': null,
              'expiresAt': '2026-12-05T00:00:00.000Z',
            },
          },
        },
      );

      final result = await repo.redeem('r1');

      expect(result.voucherCode, 'FOX-1234');
      expect(result.coinsSpent, 500);
      expect(result.remainingCoins, 740);
      expect(result.discountPhp, 100);
      expect(result.expiresAt, isNotNull);
      verify(() => api.post('/rewards/redeem', {'rewardId': 'r1'})).called(1);
    });
  });
}
