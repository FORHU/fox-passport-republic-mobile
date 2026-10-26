import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/shared/widgets/main_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                  path: '/republic',
                  builder: (_, __) => const _Tab('republic'),
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
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app(
    GoRouter router, {
    List<MatchRequestItem> requests = const [],
  }) =>
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          realtimeServiceProvider.overrideWithValue(null),
          conversationsProvider.overrideWith((ref) async => const []),
          myMatchRequestsProvider.overrideWith((ref) async => requests),
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
    router.go('/republic');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('field-republic')), 'sky hall');

    router.go('/');
    await tester.pumpAndSettle();
    expect(find.text('draft one'), findsOneWidget);

    router.go('/republic');
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
    await tester.tap(find.text('Republic'));
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

  testWidgets('the bar has the five destinations, Bookings among them', (
    tester,
  ) async {
    await tester.pumpWidget(app(_router()));
    await tester.pumpAndSettle();

    for (final label in [
      'Home',
      'Republic',
      'Bookings',
      'Messages',
      'Passport',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Map'), findsNothing);
  });

  MatchRequestItem request({required bool accepted, num total = 0}) =>
      MatchRequestItem.tryParse({
        'id': 'b-${accepted ? 'a' : 'w'}',
        'status': 'pending',
        'totalAmount': total,
        'startAt': '2099-12-20T10:00:00.000Z',
        'payments': const <Object>[],
        'event': {
          'id': 'e',
          'name': 'Match with Garden Birthday',
          'requestStatus': accepted ? 'approved' : 'pending',
        },
      })!;

  testWidgets('Bookings badge counts what needs the person', (tester) async {
    await tester.pumpWidget(
      app(
        _router(),
        requests: [
          request(accepted: true, total: 18000),
          request(accepted: false),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // One accepted request waiting for payment; the open one does not count.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('no badge when nothing needs the person', (tester) async {
    await tester.pumpWidget(app(_router()));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
  });
}
