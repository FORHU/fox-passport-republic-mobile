import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:flutter_template/features/gamification/presentation/pages/milestone_journey_page.dart';
import 'package:flutter_template/features/gamification/presentation/pages/milestones_page.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_badge.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_widgets.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/milestones_row.dart';
import 'package:flutter_template/shared/widgets/round_back_button.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _targets = [1, 5, 10, 25, 50];
const _tokens = [10, 25, 50, 100, 200];

Map<String, dynamic> _track(
  String key,
  String name,
  int count, {
  String counter = 'booked_events',
}) {
  var reached = 0;
  for (final t in _targets) {
    if (count >= t) reached++;
  }
  final next = reached < _targets.length ? reached + 1 : null;
  final nextTarget = next == null ? null : _targets[next - 1];
  final base = reached == 0 ? 0 : _targets[reached - 1];
  return {
    'key': key,
    'name': name,
    'description': null,
    'counter': counter,
    'counts': 'paid',
    'unit': 'count',
    'currentCount': count,
    'currentTier': reached,
    'nextTier': next,
    'progressPercentage':
        nextTarget == null ? 100 : ((count - base) / (nextTarget - base) * 100),
    'isCompleted': next == null,
    'tiers': [
      for (var i = 0; i < _targets.length; i++)
        {
          'tier': i + 1,
          'target': _targets[i],
          'tokens': _tokens[i],
          'badgeName': i == 1 ? 'Uncommon' : null,
          'isReached': count >= _targets[i],
        },
    ],
  };
}

MilestonesSummary _summary({int booked = 3, int attended = 1}) =>
    MilestonesSummary.fromJson({
      'milestones': [
        _track('booked_events', 'Booked events', booked),
        _track(
          'attended_events',
          'Attended events',
          attended,
          counter: 'attended_events',
        ),
        _track('cities', 'Cities visited', 1, counter: 'cities'),
      ],
      'challenges': const <Object>[],
    });

class _FakeRepository implements MilestonesRepository {
  _FakeRepository(this._answer);

  final Future<MilestonesSummary> Function() _answer;
  int calls = 0;

  @override
  Future<MilestonesSummary> mine() {
    calls++;
    return _answer();
  }
}

void main() {
  badgeTests();
  group('the milestones model', () {
    test('picks the track furthest along as the closest reward', () {
      final s = _summary();
      // Booked 3 of 5 is 50%, attended 1 of 5 is 0%, cities 1 of 5 is 0%.
      expect(s.closest?.key, 'booked_events');
      expect(s.closest?.remaining, 2);
      expect(s.closest?.next?.tokens, 25);
    });

    test('has no closest reward once every tier is reached', () {
      final s = MilestonesSummary.fromJson(<String, dynamic>{
        'milestones': [_track('booked_events', 'Booked events', 60)],
      });
      expect(s.closest, isNull);
      expect(s.milestones.single.remaining, 0);
      expect(s.milestones.single.totalTokens, 385);
    });

    test('reads a reply with fields missing instead of failing', () {
      final s = MilestonesSummary.fromJson(const <String, dynamic>{
        'milestones': [
          {'key': 'x', 'name': 'X'},
          'not a map',
        ],
      });
      expect(s.milestones, hasLength(1));
      expect(s.milestones.single.tiers, isEmpty);
      expect(s.closest, isNull);
    });
  });

  group('the screens', () {
    Future<_FakeRepository> show(
      WidgetTester tester,
      _FakeRepository repository, {
      String start = RouteNames.milestones,
    }) async {
      final router = GoRouter(
        initialLocation: RouteNames.passport,
        routes: [
          GoRoute(
            path: RouteNames.passport,
            builder: (context, state) => const Scaffold(
              body: Column(children: [MilestonesRow()]),
            ),
          ),
          GoRoute(
            path: RouteNames.milestones,
            builder: (context, state) => const MilestonesPage(),
            routes: [
              GoRoute(
                path: ':key',
                builder: (context, state) => MilestoneJourneyPage(
                  milestoneKey: state.pathParameters['key'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.search,
            builder: (context, state) =>
                Scaffold(body: Text('search ${state.uri.query}')),
          ),
        ],
      );
      tester.view
        ..physicalSize = const Size(900, 2200)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            milestonesRepositoryProvider.overrideWithValue(repository),
            currentUserIdProvider.overrideWithValue('me'),
            walletProvider.overrideWith((ref) async => throw Exception('no')),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      router.go(start);
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('list: closest reward, tracks and what is left', (
      tester,
    ) async {
      await show(tester, _FakeRepository(() async => _summary()));

      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('CLOSEST REWARD'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('2 more bookings'), findsOneWidget);
      expect(find.text('+25 Tokens'), findsWidgets);
      expect(find.text('Uncommon badge'), findsOneWidget);
      expect(find.text('Your tracks'), findsOneWidget);
      expect(find.text('Attended events'), findsOneWidget);
      expect(find.text('Cities visited'), findsOneWidget);
      expect(find.text('2 more to reach tier 2'), findsOneWidget);
      expect(find.text('TIER 1 / 5'), findsWidgets);
    });

    testWidgets('list: a track opens its journey and back returns', (
      tester,
    ) async {
      await show(tester, _FakeRepository(() async => _summary()));

      await tester.tap(find.text('Cities visited'));
      await tester.pumpAndSettle();
      expect(find.text('Your journey'), findsOneWidget);
      expect(find.text('4 more to Uncommon'), findsOneWidget);

      await tester.tap(find.byType(RoundBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Your tracks'), findsOneWidget);
    });

    testWidgets('list: Find an event opens Search on events', (tester) async {
      await show(tester, _FakeRepository(() async => _summary()));

      await tester.tap(find.text('Find an event to book'));
      await tester.pumpAndSettle();
      expect(find.text('search kind=events'), findsOneWidget);
    });

    testWidgets('list: zero progress still shows a first goal', (
      tester,
    ) async {
      await show(
        tester,
        _FakeRepository(() async => _summary(booked: 0, attended: 0)),
      );
      expect(find.text('CLOSEST REWARD'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);
      expect(find.text('1 more booking'), findsOneWidget);
    });

    testWidgets('list: nothing to show says so', (tester) async {
      await show(
        tester,
        _FakeRepository(
          () async => const MilestonesSummary([]),
        ),
      );
      expect(find.text('No milestones yet. Check back soon.'), findsOneWidget);
    });

    testWidgets('list: a failed load offers a retry that asks again', (
      tester,
    ) async {
      var offline = true;
      final repository = _FakeRepository(() async {
        if (offline) throw Exception('offline');
        return _summary();
      });
      await show(tester, repository);
      expect(find.text('Try again'), findsOneWidget);
      final before = repository.calls;

      offline = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Your tracks'), findsOneWidget);
      expect(repository.calls, greaterThan(before));
    });

    testWidgets('journey: opens on the next tier and the dots pick a tier', (
      tester,
    ) async {
      await show(
        tester,
        _FakeRepository(() async => _summary()),
        start: RouteNames.milestoneJourney('booked_events'),
      );

      expect(find.text('2 more to Uncommon'), findsOneWidget);
      // The fox is the emblem: in the ring and on the reached node.
      // One badge in the ring and one per tier, each tier its own shape.
      expect(find.byType(MilestoneBadge), findsNWidgets(6));
      expect(find.text('3 / 5 BOOKED'), findsOneWidget);
      expect(find.text('Tier 2 of 5'), findsOneWidget);
      expect(find.text('NEXT UP'), findsOneWidget);
      expect(
        find.text('Cancelled and refunded bookings do not count.'),
        findsOneWidget,
      );

      await tester.tap(
        find
            .descendant(
              of: find.byType(TierBadgeRow),
              matching: find.byType(InkResponse),
            )
            .at(3),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tier 4 of 5'), findsWidgets);
      expect(find.text('LOCKED'), findsWidgets);
    });

    testWidgets('journey: the tabs switch track without leaving the screen', (
      tester,
    ) async {
      await show(
        tester,
        _FakeRepository(() async => _summary()),
        start: RouteNames.milestoneJourney('booked_events'),
      );

      await tester.tap(find.widgetWithText(InkWell, 'Cities visited').first);
      await tester.pumpAndSettle();
      expect(find.text('4 more to Uncommon'), findsOneWidget);
      expect(find.text('Tier 2 of 5'), findsOneWidget);

      await tester.tap(find.byType(RoundBackButton));
      await tester.pumpAndSettle();
      // One step back goes to the list, not through each tab visited.
      expect(find.text('Your tracks'), findsOneWidget);
    });

    testWidgets('journey: a stale key falls back to the first track', (
      tester,
    ) async {
      await show(
        tester,
        _FakeRepository(() async => _summary()),
        start: RouteNames.milestoneJourney('gone'),
      );
      expect(find.text('2 more to Uncommon'), findsOneWidget);
    });

    testWidgets('Passport row shows the closest reward and opens the list', (
      tester,
    ) async {
      await show(
        tester,
        _FakeRepository(() async => _summary()),
        start: RouteNames.passport,
      );
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('2 more bookings'), findsOneWidget);

      await tester.tap(find.text('Milestones'));
      await tester.pumpAndSettle();
      expect(find.text('Your tracks'), findsOneWidget);
    });
  });
}

void badgeTests() {
  group('the milestone badge', () {
    for (final state in MilestoneBadgeState.values) {
      testWidgets('draws all five rarities when $state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  for (var r = 0; r < 5; r++)
                    MilestoneBadge(rarity: r, state: state),
                  // Small, as on a profile, and out-of-range values held.
                  MilestoneBadge(rarity: 9, state: state, size: 40),
                ],
              ),
            ),
          ),
        );
        expect(find.byType(MilestoneBadge), findsNWidgets(6));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
