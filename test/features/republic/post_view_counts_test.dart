import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/post_view_tracker.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_view_watcher.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

Map<String, dynamic> _json(String id, {int views = 0, String author = 'u'}) => {
      'id': id,
      'content': 'post $id',
      'tab': 'community',
      'viewsCount': views,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': author, 'name': 'Maria'},
    };

void main() {
  group('PostViewTracker (mobile#541)', () {
    late List<List<String>> calls;
    late PostViewTracker tracker;

    setUp(() {
      calls = [];
      tracker = PostViewTracker(
        myUserId: 'me',
        // Long enough that only an explicit flush sends anything.
        flushEvery: const Duration(hours: 1),
        record: (ids) async {
          calls.add(ids);
          return ids.where((id) => id != 'x').toList();
        },
      );
      addTearDown(tracker.dispose);
    });

    test('sends each post once, never your own, and says what counted',
        () async {
      final counted = <String>[];
      final sub = tracker.recorded.listen(counted.add);
      addTearDown(sub.cancel);

      tracker
        ..seen('a', authorId: 'u')
        ..seen('a', authorId: 'u')
        ..seen('mine', authorId: 'me')
        ..seen('x', authorId: 'u');
      await tracker.flush();
      await Future<void>.delayed(Duration.zero);

      expect(calls, [
        ['a', 'x'],
      ]);
      expect(counted, ['a']);

      // Already sent this session: not sent again.
      tracker.seen('a', authorId: 'u');
      await tracker.flush();
      expect(calls, hasLength(1));
    });

    test('sends at most 50 ids per call, the rest next time', () async {
      for (var i = 0; i < 60; i++) {
        tracker.seen('p$i', authorId: 'u');
      }
      await tracker.flush();
      await tracker.flush();

      expect(calls.map((c) => c.length), [50, 10]);
    });

    test('a failed call is dropped quietly', () async {
      final failing = PostViewTracker(
        myUserId: 'me',
        record: (_) async => throw Exception('offline'),
      );
      addTearDown(failing.dispose);
      failing.seen('a', authorId: 'u');

      await expectLater(failing.flush(), completes);
    });

    test('the request body and the ids read back', () async {
      final api = _MockApi();
      when(() => api.post(ApiEndpoints.feedViews, any())).thenAnswer(
        (_) async => {
          'data': {
            'recorded': ['a'],
          },
        },
      );

      expect(await RepublicRepository(api).recordViews(['a', 'b']), ['a']);
      verify(
        () => api.post('/feed/views', {
          'postIds': ['a', 'b'],
        }),
      ).called(1);
    });
  });

  group('PostViewWatcher', () {
    Future<void> pump(WidgetTester tester, VoidCallback onSeen) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PostViewWatcher(
                postId: 'a',
                onSeen: onSeen,
                child: const SizedBox(height: 200, child: Text('post')),
              ),
            ),
          ),
        );

    testWidgets('counts a post only after a second on screen, and once', (
      tester,
    ) async {
      var seen = 0;
      await pump(tester, () => seen++);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 900));
      expect(seen, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(seen, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(seen, 1);
    });

    testWidgets('a spot reused for another post counts that post too', (
      tester,
    ) async {
      final seen = <String>[];
      Widget watcher(String id) => MaterialApp(
            home: Scaffold(
              body: PostViewWatcher(
                postId: id,
                onSeen: () => seen.add(id),
                child: const SizedBox(height: 200, child: Text('post')),
              ),
            ),
          );
      await tester.pumpWidget(watcher('a'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpWidget(watcher('b'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      expect(seen, ['a', 'b']);
    });

    testWidgets('a post that leaves before a second is not counted', (
      tester,
    ) async {
      var seen = 0;
      await pump(tester, () => seen++);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 2));

      expect(seen, 0);
    });
  });

  group('the view count', () {
    Future<void> pumpCard(WidgetTester tester, int views) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostCard(
                  post: Post.fromJson(_json('a', views: views)),
                  onLike: () {},
                  onComments: () {},
                ),
              ),
            ),
          ),
        );

    testWidgets('shows in short form, and not at all at zero', (tester) async {
      await pumpCard(tester, 1200);
      expect(find.text('1.2K views'), findsOneWidget);

      await pumpCard(tester, 1);
      expect(find.text('1 view'), findsOneWidget);

      await pumpCard(tester, 0);
      expect(find.byKey(const ValueKey('post-views')), findsNothing);
    });

    test('goes up in the feed once the server counts it', () async {
      final api = _MockApi();
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': [_json('a', views: 2), _json('b')],
          'nextCursor': null,
        },
      );
      when(() => api.post(ApiEndpoints.feedViews, any())).thenAnswer(
        (_) async => {
          'data': {
            'recorded': ['a'],
          },
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(api),
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
          realtimeServiceProvider.overrideWithValue(null),
          authControllerProvider.overrideWith(_Session.new),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);

      final tracker = container.read(postViewTrackerProvider)!
        ..seen('a', authorId: 'u');
      await tracker.flush();
      await Future<void>.delayed(Duration.zero);

      final posts =
          container.read(feedControllerProvider(null)).requireValue.posts;
      expect(posts.firstWhere((p) => p.id == 'a').viewsCount, 3);
      expect(posts.firstWhere((p) => p.id == 'b').viewsCount, 0);
    });

    test('no tracker when signed out', () {
      final container = ProviderContainer(
        overrides: [
          republicRepositoryProvider.overrideWithValue(
            RepublicRepository(_MockApi()),
          ),
          authControllerProvider.overrideWith(_SignedOut.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(postViewTrackerProvider), isNull);
    });
  });
}

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthState();
}
