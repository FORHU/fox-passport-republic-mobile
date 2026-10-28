import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/citizen_profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/citizens/social_links.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_template/shared/widgets/post_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _Follows extends FollowRepository {
  _Follows() : super(_MockApi());

  @override
  Future<FollowStatus> status(String userId) async =>
      const FollowStatus(followers: 9);
}

final _json = <String, dynamic>{
  'id': 'u1',
  'name': 'Rex Santos',
  'username': 'rex',
  'bio': 'I host live music nights in Manila.',
  'socialLinks': {
    'instagram': 'https://instagram.com/rex',
    'website': 'https://rex.example.com/',
    // Not an address we would show, and not a platform we know.
    'tiktok': 'javascript:alert(1)',
    'myspace': 'https://myspace.com/rex',
  },
  'city': 'Manila',
  'country': 'Philippines',
  'roleType': ['eventFoxer'],
  'identityVerifiedAt': '2026-01-01T00:00:00Z',
  'createdAt': '2024-05-01T00:00:00Z',
  'foxerSpecializations': [
    {'id': 's', 'category': 'live_music'},
  ],
  'passport': {
    'paths': [
      {'path': 'user', 'level': 4, 'currentXP': 400},
    ],
    'stamps': [
      {
        'id': 'st1',
        'eventName': 'Launch night',
        'eventDate': '2026-03-02T00:00:00Z',
        'xpEarned': 50,
        'venue': {'name': 'The Loft', 'city': 'Manila'},
      },
    ],
    'userBadges': [
      {
        'id': 'ub1',
        'earnedAt': '2026-04-01T00:00:00Z',
        'badge': {
          'id': 'b1',
          'name': 'Early Adopter',
          'description': 'Joined early',
          'rarity': 'rare',
        },
      },
    ],
  },
  'posts': [
    {
      'id': 'p1',
      'content': 'Hello Republic',
      'likesCount': 3,
      'commentsCount': 1,
      'createdAt': '2026-05-01T00:00:00Z',
      'mediaUrls': [
        'https://img.test/a.jpg',
        'https://img.test/b.jpg',
        'https://img.test/clip.mp4',
      ],
    },
  ],
  '_count': {'posts': 12},
  'venues': [
    {'id': 'v1', 'name': 'Rex Hall', 'city': 'Manila', 'images': <Object>[]},
  ],
};

Future<void> _pump(
  WidgetTester tester, {
  Object? profile,
  MessageCitizen? onMessage,
}) async {
  // Tall enough for the whole profile, so every row is built.
  tester.view
    ..physicalSize = const Size(800, 1800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        followRepositoryProvider.overrideWithValue(_Follows()),
        citizenProfileProvider.overrideWith(
          (ref, id) async =>
              CitizenProfile.tryParse(profile) ??
              (throw const FormatException('none')),
        ),
        citizenCountsProvider.overrideWith(
          (ref, id) async =>
              const CitizenFollowCounts(followers: 9, following: 4),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CitizenProfilePage(userId: 'u1', onMessage: onMessage),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('reads level, xp, stamps, badges and offerings', () {
    final p = CitizenProfile.tryParse(_json)!;

    expect(p.level, 4);
    expect(p.xp, 400);
    expect(p.nextLevelXp, 800);
    expect(p.progress, 0.5);
    expect(p.stamps.single.place, 'The Loft');
    expect(p.badges.single.rarity, 'rare');
    expect(p.postCount, 12);
    // Only known platforms with an http(s) address are kept.
    expect(p.socialLinks, {
      SocialPlatform.instagram: 'https://instagram.com/rex',
      SocialPlatform.website: 'https://rex.example.com/',
    });
    expect(p.posts.single.mediaUrls, hasLength(3));
    expect(p.verified, isTrue);
    expect(p.specializations, ['live music']);
    expect(p.offerings.single.kind, 'venue');
    expect(CitizenProfile.tryParse({'name': 'no id'}), isNull);
  });

  test('a person with no passport starts at level 1', () {
    final p = CitizenProfile.tryParse({'id': 'u2', 'name': 'New'})!;

    expect(p.level, 1);
    expect(p.xp, 0);
    expect(p.stamps, isEmpty);
    expect(p.isPartner, isFalse);
  });

  testWidgets('shows the hero card like the web profile', (tester) async {
    await _pump(tester, profile: _json);

    expect(find.text('Rex Santos'), findsOneWidget);
    expect(find.text('@rex'), findsOneWidget);
    expect(find.text('Manila, Philippines'), findsOneWidget);
    expect(find.text('Level 4'), findsOneWidget);
    // Someone else's XP is private; their level is not.
    expect(find.text('400 / 800 XP (50%)'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.text('EVENT FOXER'), findsOneWidget);
    // Their other accounts, as links under the bio.
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('TikTok'), findsNothing);
    // With the brand's own logo, not a stand-in.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is FaIcon &&
            w.icon?.codePoint == FontAwesomeIcons.instagram.codePoint,
      ),
      findsOneWidget,
    );
    // The roles show; the categories they are tagged with do not.
    expect(find.text('live music'), findsNothing);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    // Followers and following of the person.
    expect(find.textContaining('Followers'), findsWidgets);
    // Not me, so there is a Follow button and no Edit.
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Edit profile'), findsNothing);
  });

  testWidgets('switches between stamps, badges, activity and offerings', (
    tester,
  ) async {
    await _pump(tester, profile: _json);

    expect(find.text('Launch night · Mar 2, 2026'), findsOneWidget);

    await tester.tap(find.text('Badges (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Early Adopter'), findsOneWidget);

    await tester.tap(find.text('Activity (12)'));
    // Photos keep pulsing while they load, so settle by time, not by idle.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hello Republic'), findsOneWidget);
    // Like the feed: the author's name heads the post and its photos show.
    expect(find.text('Rex Santos'), findsWidgets);
    expect(find.byType(PostMedia), findsOneWidget);
    expect(find.text('1 comment'), findsOneWidget);

    await tester.tap(find.text('Offerings'));
    await tester.pumpAndSettle();
    expect(find.text('Rex Hall'), findsOneWidget);
  });

  testWidgets('shows an empty state for no stamps', (tester) async {
    await _pump(tester, profile: {'id': 'u2', 'name': 'New'});

    expect(find.text('No venue stamps yet'), findsOneWidget);
    expect(find.text('Offerings'), findsNothing);
  });

  testWidgets('Message opens the chat through the route', (tester) async {
    final asked = <String>[];
    await _pump(
      tester,
      profile: _json,
      onMessage: (context, profile) async => asked.add(profile.id),
    );

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();

    expect(asked, ['u1']);
  });

  testWidgets('says so when the profile cannot be found', (tester) async {
    await _pump(tester, profile: 'nothing');

    expect(find.text('Citizen profile not found'), findsOneWidget);
  });

  testWidgets('your own profile shows your XP and Edit profile', (
    tester,
  ) async {
    await _pump(tester, profile: {..._json, 'id': 'me'});

    expect(find.text('400 / 800 XP (50%)'), findsOneWidget);
    // The Stamps tab is open first: what each stamp earned shows too.
    expect(find.text('+50 XP'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);
  });

  testWidgets("someone else's stamps do not show the XP they earned", (
    tester,
  ) async {
    await _pump(tester, profile: _json);

    expect(find.text('Launch night · Mar 2, 2026'), findsOneWidget);
    expect(find.text('+50 XP'), findsNothing);
  });

  testWidgets('shows their bio, and invites you to add your own', (
    tester,
  ) async {
    await _pump(tester, profile: _json);
    expect(find.text('I host live music nights in Manila.'), findsOneWidget);
    expect(find.text('Add a bio'), findsNothing);
  });

  testWidgets('your own profile without a bio offers Add a bio', (
    tester,
  ) async {
    await _pump(tester, profile: {..._json, 'id': 'me', 'bio': null});

    expect(find.text('Add a bio'), findsOneWidget);
  });

  testWidgets("someone else's empty bio shows nothing", (tester) async {
    await _pump(tester, profile: {..._json, 'bio': null});

    expect(find.text('Add a bio'), findsNothing);
  });

  testWidgets('your follower counts open who follows you; theirs do not', (
    tester,
  ) async {
    Future<void> open(String id) async {
      // A fresh router each time, so each starts on the profile.
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const CitizenProfilePage(userId: 'x'),
          ),
          GoRoute(
            path: '/profile/people',
            builder: (_, __) => const Scaffold(body: Text('PEOPLE SCREEN')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          // Its own container, so the first profile is not kept.
          key: UniqueKey(),
          overrides: [
            authControllerProvider.overrideWith(_Session.new),
            followRepositoryProvider.overrideWithValue(_Follows()),
            citizenProfileProvider.overrideWith(
              (ref, _) async => CitizenProfile.tryParse({..._json, 'id': id})!,
            ),
            citizenCountsProvider.overrideWith(
              (ref, _) async =>
                  const CitizenFollowCounts(followers: 9, following: 4),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Someone else's counts are just numbers.
    await open('u1');
    await tester.tap(find.textContaining('Followers'));
    await tester.pumpAndSettle();
    expect(find.text('PEOPLE SCREEN'), findsNothing);

    // Yours open the people page.
    await open('me');
    await tester.tap(find.textContaining('Followers'));
    await tester.pumpAndSettle();
    expect(find.text('PEOPLE SCREEN'), findsOneWidget);
  });
}
