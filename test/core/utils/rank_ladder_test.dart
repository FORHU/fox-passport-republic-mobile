import 'package:flutter_template/core/utils/rank_ladder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rankNumberForLevel', () {
    test('steps up on the server thresholds', () {
      const expected = {
        1: 1,
        2: 1,
        3: 2,
        4: 2,
        5: 3,
        9: 3,
        10: 4,
        14: 4,
        15: 5,
        19: 5,
        20: 6,
        29: 6,
        30: 7,
        39: 7,
        40: 8,
        49: 8,
        50: 9,
      };
      expected.forEach((level, rank) {
        expect(rankNumberForLevel(level), rank, reason: 'level $level');
      });
    });

    test('holds at the ends', () {
      expect(rankNumberForLevel(0), 1);
      expect(rankNumberForLevel(-4), 1);
      expect(rankNumberForLevel(80), 9);
    });
  });
}
