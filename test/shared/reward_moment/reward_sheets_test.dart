import 'package:flutter/material.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/reward_moment/rank_up_sheet.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_template/shared/reward_moment/reward_sheet.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool still = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: app!,
      ),
      home: Scaffold(body: child),
    );

const _passport = PassportSummary(
  level: 5,
  totalXp: 1000,
  levelStartXp: 800,
  nextLevelXp: 1370,
  stamps: [],
  badges: [],
);

Finder _badge(int rank) =>
    find.byWidgetPredicate((w) => w is RankBadge && w.rank == rank);

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
      PassportSummary? passport = _passport,
      void Function(RewardSheetChoice?)? onClosed,
    }) async {
      _tall(tester);
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final choice = await showRewardSheet(
                  context,
                  reward: reward,
                  passport: passport,
                );
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

    testWidgets('says what happened, and the XP and Coins it paid',
        (tester) async {
      await open(
        tester,
        const RewardMoment(xp: 100, coins: 40, action: 'attend_event'),
      );

      expect(find.text('CHECKED IN'), findsOneWidget);
      expect(find.text('You attended an event'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('COINS'), findsOneWidget);
    });

    testWidgets('shows the level and the XP left to the next', (tester) async {
      await open(
        tester,
        const RewardMoment(xp: 100, coins: 40, action: 'attend_event'),
      );

      expect(find.text('Level 5'), findsOneWidget);
      expect(find.text('370 XP to Level 6'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        find.text('XP builds your level. Coins buy discounts.'),
        findsOneWidget,
      );
    });

    testWidgets('leaves out the level bar when the passport is unknown',
        (tester) async {
      await open(
        tester,
        const RewardMoment(xp: 100, coins: 40, action: 'attend_event'),
        passport: null,
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('+100'), findsOneWidget);
    });

    testWidgets('leaves out a tile that paid nothing, and the check-in line',
        (tester) async {
      await open(
        tester,
        const RewardMoment(xp: 25, coins: 0, action: 'leave_review'),
      );

      expect(find.text('Thanks for your review'), findsOneWidget);
      expect(find.text('CHECKED IN'), findsNothing);
      expect(find.text('+25'), findsOneWidget);
      expect(find.text('COINS'), findsNothing);
    });

    testWidgets('an action it has no words for still reads well',
        (tester) async {
      await open(
        tester,
        const RewardMoment(xp: 15, coins: 3, action: 'post_feed'),
      );

      expect(find.text('You earned rewards'), findsOneWidget);
    });

    testWidgets('View my passport, Learn more and Done each say so',
        (tester) async {
      final choices = <RewardSheetChoice?>[];
      const reward = RewardMoment(xp: 100, coins: 40, action: 'attend_event');

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

  group('the rank-up sheet', () {
    Future<void> open(
      WidgetTester tester, {
      required RankUpMoment rankUp,
      required String name,
      required int level,
      bool still = true,
      List<bool?>? answers,
    }) async {
      _tall(tester);
      await tester.pumpWidget(
        _wrap(
          still: still,
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final r = await showRankUpSheet(
                  context,
                  rankUp: rankUp,
                  rankName: name,
                  level: level,
                );
                answers?.add(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('names the new rank, the level and what it paid',
        (tester) async {
      await open(
        tester,
        rankUp: const RankUpMoment(fromRank: 5, toRank: 6),
        name: 'Adventurer',
        level: 20,
      );

      expect(find.text('NEW RANK'), findsOneWidget);
      expect(find.text('Adventurer'), findsOneWidget);
      expect(find.text('Level 20 · Rank 6 of 9'), findsOneWidget);
      expect(find.text('+500 Coins'), findsOneWidget);
      expect(find.text('New badge unlocked'), findsOneWidget);
      // The Coins chip carries the Coins icon.
      expect(find.byIcon(Icons.toll_rounded), findsOneWidget);
    });

    testWidgets('shows the new badge, and the old one before it changes',
        (tester) async {
      await open(
        tester,
        rankUp: const RankUpMoment(fromRank: 5, toRank: 6),
        name: 'Adventurer',
        level: 20,
      );

      expect(_badge(6), findsOneWidget);
      expect(_badge(5), findsOneWidget);
    });

    testWidgets('plays the change with motion, and settles on the new badge',
        (tester) async {
      await open(
        tester,
        rankUp: const RankUpMoment(fromRank: 5, toRank: 6),
        name: 'Adventurer',
        level: 20,
        still: false,
      );

      expect(_badge(6), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('says how far it is to the next rank', (tester) async {
      await open(
        tester,
        rankUp: const RankUpMoment(fromRank: 5, toRank: 6),
        name: 'Adventurer',
        level: 20,
      );

      expect(find.text('Next rank: Pioneer'), findsOneWidget);
      expect(find.text('Level 30'), findsOneWidget);
      // Level 20 is the very start of the rank, but the bar is not blank.
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.05);
    });

    testWidgets('the top rank has no next rank', (tester) async {
      await open(
        tester,
        rankUp: const RankUpMoment(fromRank: 8, toRank: 9),
        name: 'Legend',
        level: 50,
      );

      expect(find.text('Level 50 · Rank 9 of 9'), findsOneWidget);
      expect(find.text('+2,000 Coins'), findsOneWidget);
      expect(find.textContaining('Next rank'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('a rank that pays nothing shows no Coins chip', (tester) async {
      await open(
        tester,
        rankUp: const RankUpMoment(fromRank: 0, toRank: 1),
        name: 'Newcomer',
        level: 1,
      );

      expect(find.textContaining('Coins'), findsNothing);
    });

    testWidgets('See my badges answers true, Done answers nothing',
        (tester) async {
      final answers = <bool?>[];
      const rankUp = RankUpMoment(fromRank: 5, toRank: 6);

      await open(
        tester,
        rankUp: rankUp,
        name: 'Adventurer',
        level: 20,
        answers: answers,
      );
      await tester.tap(find.text('See my badges'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(answers, [true, null]);
    });
  });
}
