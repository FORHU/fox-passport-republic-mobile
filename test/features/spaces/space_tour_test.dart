import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour_content.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _live = SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available');
const _draft = SpaceListing(id: 'v2', name: 'Old Barn', status: 'draft');

ProviderContainer _container({
  List<SpaceListing> venues = const [],
  PayoutSummary payouts = const PayoutSummary(),
  bool payoutsFail = false,
}) {
  final container = ProviderContainer(
    overrides: [
      myVenuesProvider.overrideWith((ref) async => venues),
      payoutsProvider.overrideWith(
        (ref) async => payoutsFail ? throw Exception('down') : payouts,
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('newFoxerProvider', () {
    test('is true with nothing live and nothing earned', () async {
      final c = _container(venues: const [_draft]);
      expect(await c.read(newFoxerProvider(NewFoxerSpace.venue).future), true);
    });

    test('is false once a listing is live', () async {
      final c = _container(venues: const [_live]);
      expect(await c.read(newFoxerProvider(NewFoxerSpace.venue).future), false);
    });

    test('is false once money is paid or on its way', () async {
      final c = _container(
        venues: const [_draft],
        payouts: const PayoutSummary(totals: PayoutTotals(pending: 100)),
      );
      expect(await c.read(newFoxerProvider(NewFoxerSpace.venue).future), false);
    });

    test('is false when the load fails', () async {
      final c = _container(payoutsFail: true);
      expect(await c.read(newFoxerProvider(NewFoxerSpace.venue).future), false);
    });
  });

  group('tour', () {
    Future<void> open(WidgetTester tester, NewFoxerSpace space, int tab) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSpaceTour(
                context,
                spaceTourSteps(AppLocalizations.of(context)!, space)[tab],
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('walks through the dashboard cards and closes', (
      tester,
    ) async {
      await open(tester, NewFoxerSpace.venue, 0);

      // Cards for parts that are not on screen are left out.
      expect(find.text('Welcome, Foxer'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Your shortcuts'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Needs you'), findsOneWidget);
      expect(find.text('Next'), findsNothing);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Needs you'), findsNothing);
    });

    testWidgets('includes an optional card once its part is on screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  tourTarget('dash-steps', const Text('the steps card')),
                  TextButton(
                    onPressed: () => showSpaceTour(
                      context,
                      spaceTourSteps(
                        AppLocalizations.of(context)!,
                        NewFoxerSpace.venue,
                      )[0],
                    ),
                    child: const Text('go'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // Welcome, shortcuts, needs you and getting started.
      expect(find.text('1 of 4'), findsOneWidget);
    });

    testWidgets('can be skipped', (tester) async {
      await open(tester, NewFoxerSpace.venue, 0);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Foxer'), findsNothing);
    });

    testWidgets('a tab with one card shows only that card', (tester) async {
      await open(tester, NewFoxerSpace.venue, 3);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('every space has a card list for each of its tabs', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(spaceTourSteps(l10n, NewFoxerSpace.venue), hasLength(5));
      expect(spaceTourSteps(l10n, NewFoxerSpace.gear), hasLength(5));
      expect(spaceTourSteps(l10n, NewFoxerSpace.services), hasLength(5));
      expect(spaceTourSteps(l10n, NewFoxerSpace.event), hasLength(5));
    });
  });
}
