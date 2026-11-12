import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _app({List<Ticket> upcoming = const [], List<Ticket> past = const []}) {
  return ProviderScope(
    overrides: [
      availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
      upcomingTicketsProvider.overrideWith((ref) async => upcoming),
      pastTicketsProvider.overrideWith((ref) async => past),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TicketsPage(),
    ),
  );
}

void main() {
  testWidgets('shows a ticket with its facts, code and actions', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(upcoming: [Ticket.sample()]));
    await tester.pumpAndSettle();

    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text('Sky Hall'), findsOneWidget);
    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('DOORS'), findsOneWidget);
    expect(find.text('GUESTS'), findsOneWidget);
    expect(find.text('FXP-0000-SAMPLE'), findsOneWidget);
    expect(find.text('Add to wallet'), findsNothing);
    expect(find.text('Directions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Past switch shows an empty message when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(_app(upcoming: [Ticket.sample()]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('No past bookings yet'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.text('Sky Hall'), findsNothing);
  });

  testWidgets('Upcoming with no bookings shows an icon and Browse events', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('No upcoming bookings yet'), findsOneWidget);
    expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
    expect(find.text('Browse events'), findsOneWidget);
  });

  group('Search is pushed over Bookings', () {
    Widget routed() => ProviderScope(
          overrides: [
            availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
            upcomingTicketsProvider.overrideWith((ref) async => const []),
            pastTicketsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const TicketsPage(),
                ),
                GoRoute(
                  path: RouteNames.search,
                  builder: (context, state) => Scaffold(
                    appBar: AppBar(),
                    body: const Text('Search page'),
                  ),
                ),
              ],
            ),
          ),
        );

    testWidgets('Browse events opens Search and Back returns to Bookings', (
      tester,
    ) async {
      await tester.pumpWidget(routed());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Browse events'));
      await tester.pumpAndSettle();
      expect(find.text('Search page'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Search page'), findsNothing);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('No upcoming bookings yet'), findsOneWidget);
    });

    testWidgets('the header search icon opens Search and Back returns', (
      tester,
    ) async {
      await tester.pumpWidget(routed());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Search page'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Bookings'), findsOneWidget);
    });
  });
}
