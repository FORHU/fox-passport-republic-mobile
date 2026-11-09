import 'package:flutter_template/core/utils/rank_info.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_test/flutter_test.dart';

WalletEntry _grant(
  String id,
  String action, {
  required DateTime at,
  int xp = 0,
  int coins = 0,
}) =>
    WalletEntry(
      id: id,
      isGrant: true,
      action: action,
      xp: xp,
      coinsDelta: coins,
      createdAt: at,
    );

WalletEntry _change(String id, DateTime at) => WalletEntry(
      id: id,
      isGrant: false,
      lifecycleType: 'REDEMPTION',
      xp: 0,
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
          _grant('a', 'attend_event', xp: 100, coins: 40, at: _after(-60)),
          _grant('b', 'leave_review', xp: 25, coins: 15, at: _after(-30)),
        ],
        level: 6,
        seenAt: null,
        seenRank: null,
      );

      expect(moments.isEmpty, isTrue);
      expect(moments.seenAt, _after(-30));
      expect(moments.seenRank, 3); // level 6 is rank 3
    });

    test('works for an account with no history yet', () {
      final moments = detectRewardMoments(
        history: const [],
        level: 1,
        seenAt: null,
        seenRank: null,
      );

      expect(moments.isEmpty, isTrue);
      expect(moments.seenAt, isNull);
      expect(moments.seenRank, 1);
    });
  });

  group('rewards', () {
    test('adds up what is newer than the last look', () {
      final moments = detectRewardMoments(
        history: [
          _grant('old', 'attend_event', xp: 100, coins: 40, at: _after(-10)),
          _grant('a', 'attend_event', xp: 100, coins: 40, at: _after(5)),
          _grant('b', 'leave_review', xp: 25, coins: 15, at: _after(8)),
        ],
        level: 5,
        seenAt: _t0,
        seenRank: 3,
      );

      expect(moments.reward!.xp, 125);
      expect(moments.reward!.coins, 55);
      expect(moments.reward!.action, 'attend_event');
      expect(moments.rankUp, isNull);
      expect(moments.seenAt, _after(8));
    });

    test('shows nothing when nothing is newer, and keeps the marker', () {
      final moments = detectRewardMoments(
        history: [_grant('a', 'attend_event', xp: 100, at: _after(-5))],
        level: 5,
        seenAt: _t0,
        seenRank: 3,
      );

      expect(moments.isEmpty, isTrue);
      expect(moments.seenAt, _t0);
    });

    test('ignores spending and other changes to Coins', () {
      final moments = detectRewardMoments(
        history: [_change('r', _after(3))],
        level: 5,
        seenAt: _t0,
        seenRank: 3,
      );

      expect(moments.reward, isNull);
    });

    test('ignores a grant that paid nothing', () {
      final moments = detectRewardMoments(
        history: [_grant('z', 'like_feed', at: _after(3))],
        level: 5,
        seenAt: _t0,
        seenRank: 3,
      );

      expect(moments.reward, isNull);
    });

    test('leaves the rank-up Coins to the rank-up sheet', () {
      final moments = detectRewardMoments(
        history: [
          _grant('a', 'attend_event', xp: 100, coins: 40, at: _after(5)),
          _grant('r', 'rank_up', coins: 500, at: _after(5)),
        ],
        level: 20,
        seenAt: _t0,
        seenRank: 5,
      );

      expect(moments.reward!.coins, 40);
    });

    test('names the biggest grant, whichever way the action is spelled', () {
      final moments = detectRewardMoments(
        history: [
          _grant('a', 'likeFeed', xp: 1, at: _after(1)),
          _grant('b', 'attendEvent', xp: 100, coins: 40, at: _after(2)),
        ],
        level: 5,
        seenAt: _t0,
        seenRank: 3,
      );

      expect(moments.reward!.action, 'attend_event');
    });
  });

  group('ranks', () {
    test('a higher rank than last time is a rank-up', () {
      final moments = detectRewardMoments(
        history: const [],
        level: 20,
        seenAt: _t0,
        seenRank: 5,
      );

      expect(moments.rankUp, const RankUpMoment(fromRank: 5, toRank: 6));
      expect(moments.reward, isNull);
      expect(moments.seenRank, 6);
    });

    test('the same rank, or a lower one after a refund, shows nothing', () {
      expect(
        detectRewardMoments(
          history: const [],
          level: 20,
          seenAt: _t0,
          seenRank: 6,
        ).rankUp,
        isNull,
      );
      final lower = detectRewardMoments(
        history: const [],
        level: 14,
        seenAt: _t0,
        seenRank: 6,
      );
      expect(lower.rankUp, isNull);
      expect(lower.seenRank, 4);
    });

    test('a jump over two ranks is one rank-up, to the rank reached', () {
      final moments = detectRewardMoments(
        history: const [],
        level: 30,
        seenAt: _t0,
        seenRank: 5,
      );

      expect(moments.rankUp, const RankUpMoment(fromRank: 5, toRank: 7));
    });
  });

  group('rank facts', () {
    test('what each rank pays matches the server ladder', () {
      expect(
        [for (var r = 1; r <= 9; r++) rankUpCoinsFor(r)],
        [0, 50, 100, 200, 300, 500, 800, 1200, 2000],
      );
      expect(rankUpCoinsFor(0), 0);
      expect(rankUpCoinsFor(10), 0);
    });

    test('the next rank is on the same ladder', () {
      expect(nextRankName('Adventurer'), 'Pioneer');
      expect(nextRankName('Maestro'), 'Icon');
      expect(nextRankName('Legend'), isNull);
      expect(nextRankName('Grandmaster'), isNull);
    });

    test('the first level of a rank, and how far through it a level is', () {
      expect(minLevelOfRank(7), 30);
      expect(minLevelOfRank(0), isNull);
      expect(rankProgress(20), 0); // start of Adventurer
      expect(rankProgress(25), 0.5); // halfway to Pioneer at 30
      expect(rankProgress(50), 1);
      expect(rankProgress(80), 1);
    });
  });
}
