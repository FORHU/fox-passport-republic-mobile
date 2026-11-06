import 'package:flutter_template/features/passport/domain/entities/foxer_passport.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_test/flutter_test.dart';

FoxerPassport _passport({int level = 3, int currentXp = 0}) => FoxerPassport(
      path: 'venueFoxer',
      level: level,
      currentXp: currentXp,
      totalXp: 0,
      perks: const [],
      badges: const [],
    );

void main() {
  test('the level is as long as the curve says', () {
    final p = _passport();

    expect(
      p.levelSpan,
      PassportSummary.xpRequiredForLevel(4) -
          PassportSummary.xpRequiredForLevel(3),
    );
  });

  test('progress is the share of the level already earned', () {
    final p = _passport(level: 2, currentXp: 140);

    expect(p.progress, closeTo(140 / p.levelSpan, 1e-9));
    expect(p.xpToNext, p.levelSpan - 140);
  });

  test('progress stays between 0 and 1 and XP to go never goes negative', () {
    final over = _passport(currentXp: 10 * 1000 * 1000);

    expect(over.progress, 1);
    expect(over.xpToNext, 0);
    expect(_passport().progress, 0);
  });
}
