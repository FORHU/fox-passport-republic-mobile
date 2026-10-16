import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/shared/widgets/main_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Two tabs and a pushed screen inside the first, laid out as the app is.
GoRouter _router() => GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              MainLayout(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, __) => const _Tab('home')),
                GoRoute(
                  path: '/notifications',
                  builder: (_, __) => const Text('NOTIFICATIONS'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (_, __) => const _Tab('search'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/tickets',
                  builder: (_, __) => const _Tab('tickets'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  builder: (_, __) => const _Tab('messages'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/passport',
                  builder: (_, __) => const _Tab('passport'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

/// A tab with a text box, so lost state shows up as lost text.
class _Tab extends StatelessWidget {
  const _Tab(this.name);

  final String name;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: TextField(key: Key('field-$name')));
}

void main() {
  Widget app(GoRouter router) => ProviderScope(
        overrides: [
          realtimeServiceProvider.overrideWithValue(null),
          conversationsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

  testWidgets('switching tabs keeps what was typed in each one', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('field-home')), 'draft one');
    router.go('/search');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-search')), 'sky hall');

    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('draft one'), findsOneWidget);

    router.go('/search');
    await tester.pumpAndSettle();
    expect(find.text('sky hall'), findsOneWidget);
  });

  testWidgets('a screen opened in one tab is still open when you come back', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    unawaited(router.push('/notifications'));
    await tester.pumpAndSettle();
    expect(find.text('NOTIFICATIONS'), findsOneWidget);

    // Through the bottom bar, as a user would.
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('NOTIFICATIONS'), findsOneWidget);
  });

  testWidgets('tapping the tab you are on returns to its first screen', (
    tester,
  ) async {
    final router = _router();
    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    unawaited(router.push('/notifications'));
    await tester.pumpAndSettle();
    expect(find.text('NOTIFICATIONS'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('NOTIFICATIONS'), findsNothing);
    expect(find.byKey(const Key('field-home')), findsOneWidget);
  });
}
