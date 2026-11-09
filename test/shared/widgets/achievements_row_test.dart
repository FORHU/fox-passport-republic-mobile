import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/achievements_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('the row opens the achievements screen', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: AchievementsRow()),
        ),
        GoRoute(
          path: RouteNames.achievements,
          builder: (_, __) => const Text('achievements screen'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    expect(find.text('Achievements'), findsOneWidget);
    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();

    expect(find.text('achievements screen'), findsOneWidget);
  });

  test('the route is where the Passport row points', () {
    expect(RouteNames.achievements, '/achievements');
  });
}
