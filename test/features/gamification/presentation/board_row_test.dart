import 'package:flutter/material.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
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
  group('BoardRow', () {
    testWidgets('shows the name and what is at the end of the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 1,
            name: 'Kai Santos',
            isMe: false,
            trailing: Text('4.8'),
          ),
        ),
      );

      expect(find.text('Kai Santos'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('a Foxer row shows its role and no rank or level', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 1,
            name: 'The Glass Pavilion',
            rolePill: 'Venue',
            isMe: false,
          ),
        ),
      );

      expect(find.text('Venue'), findsOneWidget);
      expect(find.textContaining('Level'), findsNothing);
      expect(find.textContaining('Lv'), findsNothing);
    });

    testWidgets('the caller reads "You · name" with the accent border',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BoardRow(
            position: 48,
            name: 'Ian Visperas',
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
              BoardRow(position: 3, name: 'A', isMe: false),
              BoardRow(position: 4, name: 'B', isMe: false),
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
