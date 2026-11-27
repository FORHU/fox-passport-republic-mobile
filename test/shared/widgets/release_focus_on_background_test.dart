import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/release_focus_on_background.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FocusNode> pumpField(WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => ReleaseFocusOnBackground(child: child!),
        home: Scaffold(body: TextField(focusNode: node)),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue);
    return node;
  }

  void goTo(WidgetTester tester, List<AppLifecycleState> states) =>
      states.forEach(tester.binding.handleAppLifecycleStateChanged);

  testWidgets(
    'Android: leaving the app clears the focused field, and a tap '
    'after coming back focuses it again',
    (tester) async {
      final node = await pumpField(tester);

      goTo(tester, [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      await tester.pump();
      expect(node.hasFocus, isFalse);

      goTo(tester, [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Android: a system dialog or the notification shade (inactive '
    'only) keeps the focus',
    (tester) async {
      final node = await pumpField(tester);

      goTo(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
      await tester.pump();
      expect(node.hasFocus, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'iOS keeps the focus when the app goes to the background',
    (tester) async {
      final node = await pumpField(tester);

      goTo(tester, [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      await tester.pump();
      expect(node.hasFocus, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
