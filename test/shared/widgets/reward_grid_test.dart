import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/reward_tile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _pump(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: SizedBox(
            width: 360,
            child: RewardGrid(
              children: [
                RewardTile(icon: Icons.star, title: 'One', route: '/one'),
                RewardTile(
                  icon: Icons.flag,
                  title: 'Two',
                  route: '/two',
                  hint: '2 more bookings',
                ),
                RewardTile(icon: Icons.bolt, title: 'Three', route: '/three'),
                RewardTile(icon: Icons.check, title: 'Four', route: '/four'),
              ],
            ),
          ),
        ),
      ),
      for (final p in ['one', 'two', 'three', 'four'])
        GoRoute(path: '/$p', builder: (_, __) => Text('$p screen')),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('four tiles sit two by two, a pair as tall as its taller', (
    tester,
  ) async {
    await _pump(tester);

    final one = tester.getRect(find.widgetWithText(RewardTile, 'One'));
    final two = tester.getRect(find.widgetWithText(RewardTile, 'Two'));
    final three = tester.getRect(find.widgetWithText(RewardTile, 'Three'));

    expect(one.top, two.top); // Side by side.
    expect(three.top, greaterThan(one.bottom)); // The next row.
    expect(one.height, two.height); // "Two" has a hint; "One" still matches.
    expect(find.text('2 more bookings'), findsOneWidget);
  });

  testWidgets('each tile opens its screen', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Three'));
    await tester.pumpAndSettle();

    expect(find.text('three screen'), findsOneWidget);
  });
}
