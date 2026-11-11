import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 11, 9, 10);

WalletEntry _grant(
  String action, {
  required int minutes,
  int coins = 0,
  bool pending = false,
}) =>
    WalletEntry(
      id: '$action-$minutes',
      isGrant: true,
      action: action,
      coinsDelta: coins,
      isPending: pending,
      createdAt: _t0.add(Duration(minutes: minutes)),
    );

RewardMoments _detect(List<WalletEntry> history) =>
    detectRewardMoments(history: history, seenAt: _t0);

void main() {
  group('the wallet entry', () {
    test('knows a grant is held', () {
      final held = WalletEntry.fromJson(const {
        'id': 'g1',
        'type': 'grant',
        'action': 'finish_intro',
        'coinsDelta': 20,
        'isPending': true,
        'createdAt': '2026-11-09T10:05:00.000Z',
      });
      final paid = WalletEntry.fromJson(const {
        'id': 'g2',
        'type': 'grant',
        'action': 'post_feed',
        'coinsDelta': 3,
        'isPending': false,
        'createdAt': '2026-11-09T10:05:00.000Z',
      });
      final old = WalletEntry.fromJson(const {
        'id': 'g3',
        'type': 'grant',
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
    'held Tokens on the reward sheet',
    () {
      test(
          'are not counted as earned, so a grant that is only held shows '
          'nothing', () {
        final moments = _detect([
          _grant('finish_intro', minutes: 5, coins: 20, pending: true),
        ]);

        expect(moments.reward, isNull);
      });

      test('are counted once released: the grant is then not held', () {
        final moments = _detect([
          _grant('finish_intro', minutes: 5, coins: 20),
        ]);

        expect(moments.reward!.coins, 20);
      });

      test('mix with paid Tokens: only the paid ones are counted', () {
        final moments = _detect([
          _grant('attend_event', minutes: 5, coins: 40),
          _grant(
            'complete_profile',
            minutes: 6,
            coins: 10,
            pending: true,
          ),
        ]);

        expect(moments.reward!.coins, 40);
        // The attendance is the biggest by what it actually paid.
        expect(moments.reward!.action, 'attend_event');
      });
    },
  );
}
