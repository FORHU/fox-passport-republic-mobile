import 'package:flutter/material.dart';
import 'package:flutter_template/features/gamification/presentation/pages/how_it_works_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(900, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HowItWorksPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('explains XP, Coins, earning and spending', (tester) async {
    await show(tester);

    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('XP is your progress'), findsOneWidget);
    expect(find.text('Coins are your wallet'), findsOneWidget);
    expect(find.text('How to earn'), findsOneWidget);
    expect(find.text('How to spend'), findsOneWidget);
  });

  testWidgets('states the Coin rate and that Coins are never cash', (
    tester,
  ) async {
    await show(tester);

    expect(find.textContaining('5 Coins is ₱1 off'), findsOneWidget);
    expect(find.textContaining('never cash'), findsOneWidget);
  });

  testWidgets('says nothing about things the app does not have yet', (
    tester,
  ) async {
    await show(tester);

    for (final word in ['rank', 'Rank', 'achievement', 'referral', 'streak']) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
  });

  testWidgets('fits a narrow screen without overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HowItWorksPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
