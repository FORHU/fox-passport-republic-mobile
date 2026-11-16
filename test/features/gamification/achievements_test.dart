import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/achievements_repository.dart';
import 'package:flutter_template/features/gamification/domain/achievements.dart';
import 'package:flutter_template/features/gamification/presentation/pages/achievements_page.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_badge.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/pill_chip.dart';
import 'package:flutter_template/shared/widgets/round_back_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _tiers(
  int unlocked, {
  List<int> targets = const [5, 10, 25],
  String? badge,
}) =>
    {
      'tiers': [
        for (var i = 0; i < 3; i++)
          {
            'tier': i + 1,
            'target': targets[i],
            'coins': i == 1 ? 75 : 25,
            if (i == 1 && badge != null) 'badgeName': badge,
            'isUnlocked': i < unlocked,
          },
      ],
    };

Map<String, dynamic> _a(
  String key,
  String name, {
  required int count,
  required int tier,
  required int target,
  required int percent,
  bool foxer = false,
  String? badge,
}) =>
    {
      'key': key,
      'name': name,
      'description': '$name description.',
      'category': foxer ? 'foxer' : 'citizen',
      'currentCount': count,
      'currentTier': tier,
      'nextTier': tier >= 3 ? null : tier + 1,
      'targetCount': target,
      'progressPercentage': percent,
      'isCompleted': tier >= 3,
      ..._tiers(tier, badge: badge),
    };

Map<String, dynamic> _reply() => {
      'success': true,
      'data': {
        'citizenAchievements': [
          _a('regular', 'Regular', count: 7, tier: 1, target: 10, percent: 70),
          _a(
            'stamp_collector',
            'Stamp Collector',
            count: 3,
            tier: 0,
            target: 5,
            percent: 60,
            badge: 'Venue Connoisseur',
          ),
          _a('critic', 'Critic', count: 25, tier: 3, target: 25, percent: 100),
          _a(
            'city_hopper',
            'City Hopper',
            count: 0,
            tier: 0,
            target: 3,
            percent: 0,
          ),
        ],
        'foxerAchievements': [
          _a(
            'open_for_business',
            'Open for Business',
            count: 1,
            tier: 0,
            target: 1,
            percent: 100,
            foxer: true,
          ),
        ],
        'totalUnlockedTiers': 5,
        'completedAchievements': 1,
      },
    };

void main() {
  group('the model', () {
    final summary = AchievementsSummary.fromJson(
      (_reply()['data'] as Map).cast<String, dynamic>(),
    );

    test('reads every achievement with its tiers and progress', () {
      expect(summary.citizen, hasLength(4));
      expect(summary.foxer, hasLength(1));
      final regular = summary.citizen.first;
      expect(regular.name, 'Regular');
      expect(regular.currentCount, 7);
      expect(regular.currentTier, 1);
      expect(regular.targetCount, 10);
      expect(regular.progressPercentage, 70);
      expect(regular.tiers.map((t) => t.isUnlocked), [true, false, false]);
      expect(summary.foxer.single.isFoxer, isTrue);
    });

    test('says where each one stands', () {
      expect(summary.citizen[0].state, AchievementState.inProgress);
      // Counting has begun even though no tier is reached yet.
      expect(summary.citizen[1].state, AchievementState.inProgress);
      expect(summary.citizen[2].state, AchievementState.done);
      expect(summary.citizen[3].state, AchievementState.locked);
    });

    test('the next tier carries what it pays, and a finished one has none', () {
      final next = summary.citizen[0].next!;
      expect(next.tier, 2);
      expect(next.coins, 75);
      expect(summary.citizen[1].next!.tier, 1);
      expect(summary.citizen[2].next, isNull);
    });

    test('a badge on a tier is kept, an empty one is not', () {
      final badgeTier = AchievementTier.fromJson(const {
        'tier': 2,
        'badgeName': 'Venue Connoisseur',
      });
      expect(badgeTier.badgeName, 'Venue Connoisseur');
      expect(
        AchievementTier.fromJson(const {'tier': 1, 'badgeName': ' '}).badgeName,
        isNull,
      );
    });

    test('counts tiers with and without the Foxer ones', () {
      expect(summary.totalTiers(withFoxer: false), 12);
      expect(summary.totalTiers(withFoxer: true), 15);
      // The server's count covers both; hidden Foxer ones are left out here.
      expect(summary.earned(withFoxer: true), 5);
      expect(summary.earned(withFoxer: false), 4); // 1 + 0 + 3 + 0
      expect(summary.visible(withFoxer: false), hasLength(4));
      expect(summary.visible(withFoxer: true), hasLength(5));
    });

    test('survives a reply with nothing in it', () {
      final empty = AchievementsSummary.fromJson(const {});
      expect(empty.citizen, isEmpty);
      expect(empty.earned(withFoxer: true), 0);
      expect(empty.totalTiers(withFoxer: true), 0);
    });
  });

  group('the repository', () {
    test('reads /achievements/me', () async {
      final api = _MockApi();
      when(() => api.get(ApiEndpoints.achievementsMe))
          .thenAnswer((_) async => _reply());

      final summary = await AchievementsRepository(api).mine();

      expect(summary.citizen, hasLength(4));
      verify(() => api.get('/achievements/me')).called(1);
    });

    test('refuses a reply with no data rather than guessing', () async {
      final api = _MockApi();
      when(() => api.get(ApiEndpoints.achievementsMe))
          .thenAnswer((_) async => {'success': true});

      expect(AchievementsRepository(api).mine(), throwsFormatException);
    });
  });

  group('the page', () {
    Future<void> open(
      WidgetTester tester, {
      Future<AchievementsSummary> Function()? load,
      List<String> roles = const [],
    }) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            achievementsProvider.overrideWith(
              (ref) => (load ??
                  () async => AchievementsSummary.fromJson(
                        (_reply()['data'] as Map).cast<String, dynamic>(),
                      ))(),
            ),
            authControllerProvider.overrideWith(() => _Session(roles)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AchievementsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows how many tiers are earned out of how many',
        (tester) async {
      await open(tester);

      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('4 of 12'), findsOneWidget);
      expect(find.text('earned'), findsOneWidget);
      expect(find.byType(RoundBackButton), findsOneWidget);
    });

    testWidgets(
        'opens on In progress, with tiers, progress and the next reward',
        (tester) async {
      await open(tester);

      expect(find.text('Regular'), findsOneWidget);
      expect(find.text('Stamp Collector'), findsOneWidget);
      expect(find.text('Critic'), findsNothing); // done
      expect(find.text('City Hopper'), findsNothing); // locked
      expect(find.text('7 / 10'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      // Regular is on tier 2 next: 75 Tokens, and no XP.
      expect(find.text('+75 Tokens'), findsOneWidget);
      expect(find.textContaining('XP'), findsNothing);
      // Stamp Collector's first tier has no badge; its Tokens show.
      expect(find.text('+25 Tokens'), findsOneWidget);
    });

    testWidgets('a tier with a badge says which', (tester) async {
      await open(
        tester,
        load: () async => AchievementsSummary.fromJson({
          'citizenAchievements': [
            _a(
              'stamp_collector',
              'Stamp Collector',
              count: 8,
              tier: 1,
              target: 10,
              percent: 80,
              badge: 'Venue Connoisseur',
            ),
          ],
          'foxerAchievements': const <Object>[],
          'totalUnlockedTiers': 1,
        }),
      );

      expect(find.text('Badge: Venue Connoisseur'), findsOneWidget);
    });

    testWidgets('Done and Locked show their own', (tester) async {
      await open(tester);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Critic'), findsOneWidget);
      expect(find.text('All three tiers done'), findsOneWidget);
      expect(find.text('Regular'), findsNothing);

      await tester.tap(find.text('Locked'));
      await tester.pumpAndSettle();
      expect(find.text('City Hopper'), findsOneWidget);
      expect(find.text('Critic'), findsNothing);
    });

    testWidgets('a citizen sees no Foxer achievements', (tester) async {
      await open(tester);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('In progress'));
      await tester.pumpAndSettle();

      expect(find.text('Open for Business'), findsNothing);
      expect(find.text('FOXER'), findsNothing);
    });

    testWidgets('a Foxer sees theirs too, under their own heading',
        (tester) async {
      await open(tester, roles: ['venueFoxer']);

      expect(find.text('4 of 15'), findsNothing);
      expect(find.text('5 of 15'), findsOneWidget);
      expect(find.text('CITIZEN'), findsOneWidget);
      expect(find.text('FOXER'), findsOneWidget);
      expect(find.text('Open for Business'), findsOneWidget);
    });

    testWidgets('an empty filter says so', (tester) async {
      await open(
        tester,
        load: () async => AchievementsSummary.fromJson({
          'citizenAchievements': [
            _a(
              'critic',
              'Critic',
              count: 25,
              tier: 3,
              target: 25,
              percent: 100,
            ),
          ],
          'foxerAchievements': const <Object>[],
          'totalUnlockedTiers': 3,
        }),
      );

      expect(
        find.text('Nothing in progress yet. Book, attend or review to start.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry', (tester) async {
      var calls = 0;
      await open(
        tester,
        load: () async {
          calls++;
          throw Exception('offline');
        },
      );

      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    });

    testWidgets('the three filters share one row', (tester) async {
      await open(tester);

      final progress =
          tester.getTopLeft(find.widgetWithText(PillChip, 'In progress'));
      final done = tester.getTopLeft(find.widgetWithText(PillChip, 'Done'));
      final locked = tester.getTopLeft(find.widgetWithText(PillChip, 'Locked'));
      expect(done.dy, progress.dy);
      expect(locked.dy, progress.dy);
      // Side by side, not each filling the width.
      expect(done.dx, greaterThan(progress.dx));
      expect(locked.dx, greaterThan(done.dx));
    });

    testWidgets('tiers are badges: three shapes, filled, outlined or grey',
        (tester) async {
      await open(tester);

      final badges =
          tester.widgetList<MilestoneBadge>(find.byType(MilestoneBadge));
      expect(badges, isNotEmpty);
      // Tier 1, 2 and 3 are the circle, ringed circle and hexagon.
      expect({for (final b in badges) b.rarity}, {0, 1, 2});
      // A reached tier is filled and a coming one is not.
      expect(
        badges.map((b) => b.state),
        containsAll([MilestoneBadgeState.earned, MilestoneBadgeState.next]),
      );
    });

    testWidgets('names each tier for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester);

      expect(find.bySemanticsLabel(RegExp('Tier 1 done')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Tier 2 not yet')), findsWidgets);
      handle.dispose();
    });
  });
}

/// Someone signed in who holds the given roles.
class _Session extends AuthController {
  _Session(this._roles);

  final List<String> _roles;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ian',
          roleType: _roles,
        ),
      );
}
