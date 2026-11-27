import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/venues/coverage_area.dart';
import 'package:flutter_test/flutter_test.dart';

/// mobile#498: the six areas, as the API's VenueCoverage, with their words.
void main() {
  test('the six areas, narrowest first, as the API names them', () {
    expect(venueCoverageAreas, [
      'local',
      'municipal',
      'city',
      'province',
      'national',
      'international',
    ]);
  });

  testWidgets('each has a name and a line saying what it means', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(coverageAreaLabel(l10n, 'city'), 'City-wide');
    expect(coverageAreaHint(l10n, 'city'), 'Throughout the city.');
    expect(coverageAreaLabel(l10n, 'international'), 'International');
    for (final code in venueCoverageAreas) {
      expect(coverageAreaLabel(l10n, code), isNot(code));
      expect(coverageAreaHint(l10n, code), isNotEmpty);
    }
    // An area the app doesn't know yet shows as it came.
    expect(coverageAreaLabel(l10n, 'galaxy'), 'galaxy');
  });
}
