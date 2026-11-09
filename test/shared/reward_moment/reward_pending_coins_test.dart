import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 11, 9, 10);

WalletEntry _grant(
  String action, {
  required int minutes,
  int xp = 0,
  int coins = 0,
  bool pending = false,
}) =>
    WalletEntry(
      id: '$action-$minutes',
      isGrant: true,
      action: action,
      xp: xp,
      coinsDelta: coins,
      isPending: pending,
      createdAt: _t0.add(Duration(minutes: minutes)),
    );

RewardMoments _detect(List<WalletEntry> history) => detectRewardMoments(
      history: history,
      level: 5,
      seenAt: _t0,
      seenRank: 3,
    );

void main() {
  group('the wallet entry', () {
    test('knows a grant is held', () {
      final held = WalletEntry.fromJson(const {
        'id': 'g1',
        'type': 'grant',
        'action': 'finish_intro',
        'xp': 50,
        'coinsDelta': 20,
        'isPending': true,
        'createdAt': '2026-11-09T10:05:00.000Z',
      });
      final paid = WalletEntry.fromJson(const {
        'id': 'g2',
        'type': 'grant',
        'action': 'post_feed',
        'xp': 15,
        'coinsDelta': 3,
        'isPending': false,
        'createdAt': '2026-11-09T10:05:00.000Z',
      });
      final old = WalletEntry.fromJson(const {
        'id': 'g3',
        'type': 'grant',
        'xp': 1,
        'coinsDelta': 0,
        'createdAt': '2026-11-09T10:05:00.000Z',
      });

      expect(held.isPending, isTrue);
      expect(paid.isPending, isFalse);
      // An API that does not send the flag yet means nothing is held.
      expect(old.isPending, isFalse);
    });
  });

  group(
    'held Coins on the reward sheet',
    () {
      test('are not counted as earned, though the XP is', () {
        final moments = _detect([
          _grant('finish_intro', minutes: 5, xp: 50, coins: 20, pending: true),
        ]);

        expect(moments.reward!.xp, 50);
        expect(moments.reward!.coins, 0);
      });

      test('a grant that only held Coins and paid no XP shows nothing', () {
        final moments = _detect([
          _grant('some_rule', minutes: 5, coins: 20, pending: true),
        ]);

        expect(moments.reward, isNull);
      });

      test('are counted once released: the grant is then not held', () {
        final moments = _detect([
          _grant('finish_intro', minutes: 5, xp: 50, coins: 20),
        ]);

        expect(moments.reward!.coins, 20);
      });

      test('mix with paid Coins: only the paid ones are counted', () {
        final moments = _detect([
          _grant('attend_event', minutes: 5, xp: 100, coins: 40),
          _grant(
            'complete_profile',
            minutes: 6,
            xp: 30,
            coins: 10,
            pending: true,
          ),
        ]);

        expect(moments.reward!.xp, 130);
        expect(moments.reward!.coins, 40);
        // The attendance is the biggest by what it actually paid.
        expect(moments.reward!.action, 'attend_event');
      });
    },
  );
}
