import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_template/shared/reward_moment/reward_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 1800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('the reward sheet', () {
    Future<void> open(
      WidgetTester tester,
      RewardMoment reward, {
      void Function(RewardSheetChoice?)? onClosed,
    }) async {
      _tall(tester);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final choice = await showRewardSheet(context, reward: reward);
                onClosed?.call(choice);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('says what happened, and the Tokens it paid', (tester) async {
      await open(tester, const RewardMoment(coins: 40, action: 'attend_event'));

      expect(find.text('CHECKED IN'), findsOneWidget);
      expect(find.text('You attended an event'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);
      expect(find.text('TOKENS'), findsOneWidget);
      expect(find.byIcon(Icons.toll_rounded), findsOneWidget);
    });

    testWidgets('shows no XP, level or level bar', (tester) async {
      await open(tester, const RewardMoment(coins: 40, action: 'attend_event'));

      expect(find.textContaining('XP'), findsNothing);
      expect(find.textContaining('Level'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Tokens buy discounts.'), findsOneWidget);
    });

    testWidgets('leaves out the check-in line when it was not an attendance',
        (tester) async {
      await open(tester, const RewardMoment(coins: 15, action: 'leave_review'));

      expect(find.text('Thanks for your review'), findsOneWidget);
      expect(find.text('CHECKED IN'), findsNothing);
      expect(find.text('+15'), findsOneWidget);
    });

    testWidgets('an action it has no words for still reads well',
        (tester) async {
      await open(tester, const RewardMoment(coins: 3, action: 'post_feed'));

      expect(find.text('You earned rewards'), findsOneWidget);
    });

    testWidgets('View my passport, Learn more and Done each say so',
        (tester) async {
      final choices = <RewardSheetChoice?>[];
      const reward = RewardMoment(coins: 40, action: 'attend_event');

      await open(tester, reward, onClosed: choices.add);
      await tester.tap(find.text('View my passport'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn more'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(choices, [
        RewardSheetChoice.viewPassport,
        RewardSheetChoice.learnMore,
        null,
      ]);
    });
  });
}
