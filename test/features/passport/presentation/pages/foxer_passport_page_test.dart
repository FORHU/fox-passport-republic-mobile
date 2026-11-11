import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/foxer_passport.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/passport/presentation/pages/foxer_passport_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    Future<FoxerPassport> Function() load,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foxerPassportProvider('venueFoxer').overrideWith((ref) => load()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FoxerPassportPage(path: 'venueFoxer'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows perks and badges, and no level, rank, XP or Tokens', (
    tester,
  ) async {
    await show(
      tester,
      () async => const FoxerPassport(
        path: 'venueFoxer',
        perks: ['venue_authority', 'city_badge'],
        badges: [
          PassportBadge(id: 'b1', name: 'Host Master', earned: true),
          PassportBadge(id: 'b2', name: 'City Builder', earned: false),
        ],
      ),
    );

    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('Venue authority'), findsOneWidget);
    expect(find.text('City badge'), findsOneWidget);
    expect(find.text('Host Master'), findsOneWidget);
    expect(find.text('City Builder'), findsOneWidget);
    expect(find.textContaining('Level'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.textContaining('Tokens'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a new Foxer sees what is still to come, not an empty box', (
    tester,
  ) async {
    await show(
      tester,
      () async => const FoxerPassport(
        path: 'venueFoxer',
        perks: [],
        badges: [],
      ),
    );

    expect(find.text('No perks yet.'), findsOneWidget);
    expect(
      find.text('Badges you earn in this role show up here.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load says so and offers a retry', (tester) async {
    await show(tester, () async => throw Exception('offline'));

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Perks'), findsNothing);
  });

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('fits ${width.toInt()} px, text x$scale', (tester) async {
        tester.view
          ..physicalSize = Size(width, 740)
          ..devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearAllTestValues();
        });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              foxerPassportProvider('venueFoxer').overrideWith(
                (ref) async => const FoxerPassport(
                  path: 'venueFoxer',
                  perks: [
                    'venue_authority_and_city_badge',
                    'early_bird_priority_access',
                    'a_very_long_perk_key_for_a_narrow_screen',
                  ],
                  badges: [
                    PassportBadge(
                      id: 'b1',
                      name: 'The Grand Host Master of the Whole City',
                      earned: true,
                    ),
                    PassportBadge(
                      id: 'b2',
                      name: 'City Builder and Nightlife Pioneer',
                      earned: false,
                    ),
                  ],
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const FoxerPassportPage(path: 'venueFoxer'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Passport'), findsOneWidget);
      });
    }
  }

  test('perk keys read as words', () {
    expect(perkLabel('venue_authority'), 'Venue authority');
    expect(perkLabel('early_bird'), 'Early bird');
    expect(perkLabel(''), '');
  });
}
