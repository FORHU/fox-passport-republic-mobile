import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/tickets_skeleton.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: Scaffold(body: child),
        ),
      ),
    );

/// The pulse's own fade; the route and the scaffold have fades of their own.
double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(SkeletonPulse),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  group('SkeletonPulse', () {
    testWidgets('breathes: the boxes fade up and down', (tester) async {
      await tester.pumpWidget(
        _wrap(const SkeletonPulse(child: SkeletonBox(height: 20))),
      );
      final start = _opacity(tester);

      await tester.pump(const Duration(milliseconds: 550));
      final middle = _opacity(tester);
      await tester.pump(const Duration(milliseconds: 550));
      final end = _opacity(tester);

      expect(middle, isNot(closeTo(start, 0.05)));
      expect({start, middle, end}.length, greaterThan(1));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('sits still when the user asked for reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SkeletonPulse(child: SkeletonBox(height: 20)),
          reduceMotion: true,
        ),
      );

      // With nothing animating, this settles at once; a pulse would time out.
      await tester.pumpAndSettle();
      expect(_opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a screen reader hears "Loading" once, not the shapes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          const SkeletonPulse(
            child: Column(
              children: [SkeletonBox(height: 20), SkeletonBox(height: 20)],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Tickets while loading', () {
    late Completer<List<Ticket>> upcoming;
    late Completer<List<Ticket>> past;
    late Completer<List<MatchRequestItem>> requests;

    Future<void> open(WidgetTester tester) async {
      // Made here, not in setUp: a Completer from outside the test body is not
      // on the test's fake clock, so pump would never deliver its answer.
      upcoming = Completer<List<Ticket>>();
      past = Completer<List<Ticket>>();
      requests = Completer<List<MatchRequestItem>>();
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
            upcomingTicketsProvider.overrideWith((ref) => upcoming.future),
            pastTicketsProvider.overrideWith((ref) => past.future),
            myMatchRequestsProvider.overrideWith((ref) => requests.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TicketsPage(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Upcoming shows ticket-shaped skeletons, not a spinner', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(TicketsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      upcoming.complete([Ticket.sample()]);
      await tester.pump();
      await tester.pump();

      expect(find.byType(TicketsSkeleton), findsNothing);
      expect(find.text('Sky Hall'), findsOneWidget);
    });

    testWidgets('Past shows the same while it loads', (tester) async {
      await open(tester);
      upcoming.complete(const []);
      await tester.pump();

      await tester.tap(find.text('Past'));
      await tester.pump();

      expect(find.byType(TicketsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Requests shows card-shaped skeletons', (tester) async {
      await open(tester);

      await tester.tap(find.text('Requests'));
      await tester.pump();

      expect(find.byType(RequestsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
