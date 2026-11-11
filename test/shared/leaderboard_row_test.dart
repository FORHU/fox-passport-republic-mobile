import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/leaderboard_row.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('opens the Foxer leaderboard', (tester) async {
    var opened = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: LeaderboardRow()),
        ),
        GoRoute(
          path: RouteNames.leaderboard,
          builder: (context, state) {
            opened = true;
            return const Scaffold(body: Text('opened'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.text('opened'), findsOneWidget);
  });
}
