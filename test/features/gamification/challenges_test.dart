import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:flutter_template/features/gamification/presentation/pages/challenges_page.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/challenges_row.dart';
import 'package:flutter_template/shared/widgets/round_back_button.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Map<String, dynamic> _challenge(
  String key,
  String name,
  String period,
  int target,
  int count, {
  int tokens = 0,
}) =>
    {
      'key': key,
      'name': name,
      'description': null,
      'period': period,
      'target': target,
      'tokens': tokens,
      'currentCount': count,
      'isCompleted': count >= target,
      'periodStart': '2026-11-09T16:00:00.000Z',
      'periodEnd': '2026-11-16T16:00:00.000Z',
    };

MilestonesSummary _summary({int tokens = 0}) => MilestonesSummary.fromJson({
      'milestones': const <Object>[],
      'challenges': [
        _challenge('book_today', 'Book today', 'day', 1, 0, tokens: tokens),
        _challenge(
          'weekly_regular',
          'Weekly regular',
          'week',
          3,
          1,
          tokens: tokens,
        ),
        _challenge(
          'monthly_explorer',
          'Monthly explorer',
          'month',
          5,
          5,
          tokens: tokens,
        ),
      ],
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
  group('the challenge model', () {
    test('reads period, target, count and what it pays', () {
      final c = _summary(tokens: 20).challenges[1];
      expect(c.period, ChallengePeriod.week);
      expect(c.target, 3);
      expect(c.currentCount, 1);
      expect(c.tokens, 20);
      expect(c.isCompleted, isFalse);
      expect(c.progress, closeTo(1 / 3, 0.001));
    });

    test('is done when the count reaches the target, even unflagged', () {
      final c = Challenge.fromJson(const <String, dynamic>{
        'key': 'x',
        'name': 'X',
        'period': 'day',
        'target': 2,
        'currentCount': 3,
      });
      expect(c.isCompleted, isTrue);
      expect(c.progress, 1);
    });

    test('survives a reply with fields missing', () {
      final s = MilestonesSummary.fromJson(const <String, dynamic>{
        'challenges': [
          {'key': 'x'},
          'not a map',
        ],
      });
      expect(s.challenges, hasLength(1));
      expect(s.challenges.single.progress, 0);
      expect(s.milestones, isEmpty);
    });
  });

  group('the Challenges screen', () {
    Future<_FakeRepository> show(
      WidgetTester tester,
      _FakeRepository repository, {
      String start = RouteNames.challenges,
    }) async {
      final router = GoRouter(
        initialLocation: RouteNames.passport,
        routes: [
          GoRoute(
            path: RouteNames.passport,
            builder: (context, state) =>
                const Scaffold(body: Column(children: [ChallengesRow()])),
          ),
          GoRoute(
            path: RouteNames.challenges,
            builder: (context, state) => const ChallengesPage(),
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

    testWidgets('lists each challenge with its period and count', (
      tester,
    ) async {
      await show(tester, _FakeRepository(() async => _summary()));

      expect(find.text('Challenges'), findsOneWidget);
      expect(find.text('BOOKING CHALLENGES'), findsOneWidget);
      expect(find.text('Book today'), findsOneWidget);
      expect(find.text('Day · 0 of 1 booking'), findsOneWidget);
      expect(find.text('Week · 1 of 3 bookings'), findsOneWidget);
      expect(
        find.text('Tokens stay pending until the bookings are attended.'),
        findsOneWidget,
      );
    });

    testWidgets('a finished challenge says Done', (tester) async {
      await show(tester, _FakeRepository(() async => _summary()));

      expect(find.text('DONE'), findsOneWidget);
      expect(find.text('Month · 5 of 5 bookings'), findsOneWidget);
    });

    testWidgets('shows no "+0" while no amount is set', (tester) async {
      await show(tester, _FakeRepository(() async => _summary()));
      expect(find.textContaining('+0'), findsNothing);
      expect(find.text('Tokens'), findsNothing);
    });

    testWidgets('shows what a challenge pays once an amount is set', (
      tester,
    ) async {
      await show(tester, _FakeRepository(() async => _summary(tokens: 20)));
      // The two unfinished ones show it; the finished one says Done instead.
      expect(find.text('+20'), findsNWidgets(2));
      expect(find.text('Tokens'), findsNWidgets(2));
    });

    testWidgets('nothing to show says so', (tester) async {
      await show(
        tester,
        _FakeRepository(() async => const MilestonesSummary([])),
      );
      expect(
        find.text('No challenges right now. Check back soon.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry that asks again', (tester) async {
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

      expect(find.text('Book today'), findsOneWidget);
      expect(repository.calls, greaterThan(before));
    });

    testWidgets('the Passport row opens it and back returns', (tester) async {
      await show(
        tester,
        _FakeRepository(() async => _summary()),
        start: RouteNames.passport,
      );
      await tester.tap(find.text('Challenges'));
      await tester.pumpAndSettle();
      expect(find.text('Book today'), findsOneWidget);

      await tester.tap(find.byType(RoundBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Book today'), findsNothing);
      expect(find.text('Challenges'), findsOneWidget);
    });
  });
}
