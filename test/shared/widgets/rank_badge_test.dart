import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

String _assetOf(WidgetTester tester) {
  final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
  return (picture.bytesLoader as SvgAssetLoader).assetName;
}

void main() {
  testWidgets('every badge file parses and draws', (tester) async {
    const files = [
      'rank-1-newcomer',
      'rank-2-wanderer',
      'rank-3-explorer',
      'rank-4-trailblazer',
      'rank-5-voyager',
      'rank-6-adventurer',
      'rank-7-pioneer',
      'rank-8-vanguard',
      'rank-9-legend',
    ];
    await tester.runAsync(() async {
      for (final file in files) {
        final info = await vg.loadPicture(
          SvgAssetLoader('assets/badges/$file.svg'),
          null,
        );
        expect(info.size.width, greaterThan(0), reason: file);
        expect(info.size.height, greaterThan(0), reason: file);
        info.picture.dispose();
      }
    });
  });

  testWidgets('draws one badge per rank, 1 to 9', (tester) async {
    const files = [
      'rank-1-newcomer',
      'rank-2-wanderer',
      'rank-3-explorer',
      'rank-4-trailblazer',
      'rank-5-voyager',
      'rank-6-adventurer',
      'rank-7-pioneer',
      'rank-8-vanguard',
      'rank-9-legend',
    ];
    for (var rank = 1; rank <= 9; rank++) {
      await tester.pumpWidget(_wrap(RankBadge(rank: rank)));
      expect(_assetOf(tester), 'assets/badges/${files[rank - 1]}.svg');
    }
  });

  testWidgets('clamps a rank outside 1 to 9', (tester) async {
    await tester.pumpWidget(_wrap(const RankBadge(rank: 0)));
    expect(_assetOf(tester), 'assets/badges/rank-1-newcomer.svg');
    await tester.pumpWidget(_wrap(const RankBadge(rank: 12)));
    expect(_assetOf(tester), 'assets/badges/rank-9-legend.svg');
  });

  testWidgets('picks the badge a level has earned', (tester) async {
    await tester.pumpWidget(_wrap(RankBadge.forLevel(15)));
    expect(_assetOf(tester), 'assets/badges/rank-5-voyager.svg');
  });

  testWidgets('keeps the 10:11 shape of the drawing', (tester) async {
    await tester.pumpWidget(_wrap(const RankBadge(rank: 3, size: 110)));
    final size = tester.getSize(find.byType(SvgPicture));
    expect(size.height, 110);
    expect(size.width, closeTo(100, 0.01));
  });

  testWidgets('is silent to screen readers without a label, named with one',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const RankBadge(rank: 3)));
    expect(find.bySemanticsLabel('Explorer'), findsNothing);

    await tester.pumpWidget(_wrap(const RankBadge(rank: 3, label: 'Explorer')));
    expect(find.bySemanticsLabel('Explorer'), findsOneWidget);
    handle.dispose();
  });
}
