import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_test/flutter_test.dart';

WalletEntry _grant(
  String id,
  String action, {
  required DateTime at,
  int coins = 0,
}) =>
    WalletEntry(
      id: id,
      isGrant: true,
      action: action,
      coinsDelta: coins,
      createdAt: at,
    );

WalletEntry _change(String id, DateTime at) => WalletEntry(
      id: id,
      isGrant: false,
      lifecycleType: 'REDEMPTION',
      coinsDelta: -100,
      createdAt: at,
    );

final _t0 = DateTime.utc(2026, 11, 9, 10);
DateTime _after(int minutes) => _t0.add(Duration(minutes: minutes));

void main() {
  group('the first look on this phone', () {
    test('shows nothing, and remembers what is there', () {
      final moments = detectRewardMoments(
        history: [
          _grant('a', 'attend_event', coins: 40, at: _after(-60)),
          _grant('b', 'leave_review', coins: 15, at: _after(-30)),
        ],
        seenAt: null,
      );

      expect(moments.isEmpty, isTrue);
      expect(moments.seenAt, _after(-30));
    });

    test('works for an account with no history yet', () {
      final moments = detectRewardMoments(history: const [], seenAt: null);

      expect(moments.isEmpty, isTrue);
      expect(moments.seenAt, isNull);
    });
  });

  group('rewards', () {
    test('adds up what is newer than the last look', () {
      final moments = detectRewardMoments(
        history: [
          _grant('old', 'attend_event', coins: 40, at: _after(-10)),
          _grant('a', 'attend_event', coins: 40, at: _after(5)),
          _grant('b', 'leave_review', coins: 15, at: _after(8)),
        ],
        seenAt: _t0,
      );

      expect(moments.reward!.coins, 55);
      expect(moments.reward!.action, 'attend_event');
      expect(moments.seenAt, _after(8));
    });

    test('shows nothing when nothing is newer, and keeps the marker', () {
      final moments = detectRewardMoments(
        history: [_grant('a', 'attend_event', coins: 40, at: _after(-5))],
        seenAt: _t0,
      );

      expect(moments.isEmpty, isTrue);
      expect(moments.seenAt, _t0);
    });

    test('ignores spending and other changes to Tokens', () {
      final moments = detectRewardMoments(
        history: [_change('r', _after(3))],
        seenAt: _t0,
      );

      expect(moments.reward, isNull);
    });

    test('ignores a grant that paid nothing', () {
      final moments = detectRewardMoments(
        history: [_grant('z', 'like_feed', at: _after(3))],
        seenAt: _t0,
      );

      expect(moments.reward, isNull);
    });

    test('names the biggest grant, whichever way the action is spelled', () {
      final moments = detectRewardMoments(
        history: [
          _grant('a', 'likeFeed', coins: 1, at: _after(1)),
          _grant('b', 'attendEvent', coins: 40, at: _after(2)),
        ],
        seenAt: _t0,
      );

      expect(moments.reward!.action, 'attend_event');
    });
  });
}
