import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/rank_ladder.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('rankNumberForName', () {
    test('knows every rank on both ladders', () {
      const citizen = [
        'Newcomer',
        'Wanderer',
        'Explorer',
        'Trailblazer',
        'Voyager',
        'Adventurer',
        'Pioneer',
        'Vanguard',
        'Legend',
      ];
      const foxer = [
        'Rookie',
        'Regular',
        'Pro',
        'Veteran',
        'Headliner',
        'Maestro',
        'Icon',
        'Luminary',
        'Legend',
      ];
      for (var i = 0; i < 9; i++) {
        expect(rankNumberForName(citizen[i]), i + 1, reason: citizen[i]);
        expect(rankNumberForName(foxer[i]), i + 1, reason: foxer[i]);
      }
    });

    test('ignores case and spaces, and is null for a name it does not know',
        () {
      expect(rankNumberForName('  explorer '), 3);
      expect(rankNumberForName('Grandmaster'), isNull);
      expect(rankNumberForName(''), isNull);
    });
  });

  test('rank colours go grey, green, cyan, magenta, with lime for Legend only',
      () {
    expect(rankColor(1), AppColors.rarityCommon);
    expect(rankColor(2), AppColors.rarityCommon);
    expect(rankColor(3), AppColors.rarityUncommon);
    expect(rankColor(4), AppColors.rarityUncommon);
    expect(rankColor(5), AppColors.rarityRare);
    expect(rankColor(6), AppColors.rarityRare);
    expect(rankColor(7), AppColors.rarityEpic);
    expect(rankColor(8), AppColors.rarityEpic);
    expect(rankColor(9), AppColors.rarityLegendary);
    for (var r = 1; r <= 8; r++) {
      expect(rankColor(r), isNot(AppColors.rarityLegendary));
    }
  });

  group('BoardRow', () {
    testWidgets('shows the badge and the rank name in the rank colour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 1,
            name: 'Kai Santos',
            rankName: 'Adventurer',
            rank: 6,
            isMe: false,
            trailing: Text('Lv 22'),
          ),
        ),
      );

      expect(find.text('Kai Santos'), findsOneWidget);
      expect(find.text('Lv 22'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RankBadge && w.rank == 6),
        findsOneWidget,
      );
      expect(_colorOf(tester, 'Adventurer'), AppColors.rarityRare);
    });

    testWidgets('without a known rank it shows the name only, in grey',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 4,
            name: 'Mika',
            rankName: 'Grandmaster',
            isMe: false,
          ),
        ),
      );

      expect(find.byType(RankBadge), findsNothing);
      expect(_colorOf(tester, 'Grandmaster'), AppColors.textSecondary);
    });

    testWidgets('a Foxer row puts the role before the rank', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 1,
            name: 'The Glass Pavilion',
            rankName: 'Icon',
            rank: 7,
            rolePill: 'Venue',
            isMe: false,
          ),
        ),
      );

      final pill = tester.getTopLeft(find.text('Venue')).dx;
      final badge = tester.getTopLeft(find.byType(RankBadge)).dx;
      final rank = tester.getTopLeft(find.text('Icon')).dx;
      expect(pill, lessThan(badge));
      expect(badge, lessThan(rank));
    });

    testWidgets('the caller reads "You · name" with the accent border',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 48,
            name: 'Ian Visperas',
            rankName: 'Explorer',
            rank: 3,
            isMe: true,
          ),
        ),
      );

      expect(find.text('You · Ian Visperas'), findsOneWidget);
      expect(find.text('Ian Visperas'), findsNothing);
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BoardRow),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, AppColors.accent);
    });

    testWidgets('the top three positions are brighter than the rest',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              BoardRow(position: 3, name: 'A', rankName: 'Pro', isMe: false),
              BoardRow(position: 4, name: 'B', rankName: 'Pro', isMe: false),
            ],
          ),
        ),
      );

      expect(_colorOf(tester, '3'), AppColors.textPrimary);
      expect(_colorOf(tester, '4'), AppColors.textSecondary);
    });
  });

  group('BoardChip', () {
    testWidgets('is white when chosen and dark when not, and taps',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              BoardChip(
                label: 'This month',
                selected: true,
                onTap: () => taps++,
              ),
              BoardChip(label: 'All time', selected: false, onTap: () {}),
            ],
          ),
        ),
      );

      expect(_colorOf(tester, 'This month'), AppColors.canvas);
      expect(_colorOf(tester, 'All time'), AppColors.textSecondary);
      await tester.tap(find.text('This month'));
      expect(taps, 1);
      // A thumb-sized target.
      expect(
        tester.getSize(find.byType(BoardChip).first).height,
        greaterThanOrEqualTo(40),
      );
    });
  });
}
