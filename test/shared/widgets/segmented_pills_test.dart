import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pills({ValueChanged<int>? onChanged}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SegmentedPills<int>(
            options: const [
              SegmentOption(1, 'Progress'),
              SegmentOption(2, 'Stamps'),
              SegmentOption(3, 'Matches'),
            ],
            value: 1,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('every pill has a tap target of at least 44 and a label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_pills());

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the control keeps its look: 50 tall, pills 40 tall', (
    tester,
  ) async {
    await tester.pumpWidget(_pills());

    final control = tester.getSize(find.byType(SegmentedPills<int>));
    expect(control.height, 50);
    final selected = tester.getSize(
      find.ancestor(
        of: find.text('Progress'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(selected.height, 40);
  });

  testWidgets('a tap just above or below the pill still counts', (
    tester,
  ) async {
    int? picked;
    await tester.pumpWidget(_pills(onChanged: (v) => picked = v));

    final pill = tester.getRect(
      find.ancestor(
        of: find.text('Stamps'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    // 1px above the pill's top edge: outside the pill, inside the 44px area.
    await tester.tapAt(Offset(pill.center.dx, pill.top - 1));
    await tester.pump();

    expect(picked, 2);
  });
}
