import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/media_viewer.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/shared/widgets/post_media.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _post({
  String id = '1',
  int likes = 0,
  String? mine,
  bool liked = false,
  List<String> media = const [],
  Map<String, int>? counts,
}) =>
    {
      'id': id,
      'content': 'Post $id',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'likesCount': likes,
      'myReaction': mine,
      'isLikedByMe': liked,
      'mediaUrls': media,
      'author': {'id': 'u', 'name': 'Maria'},
      if (counts != null)
        'reactionCounts': [
          for (final e in counts.entries) {'type': e.key, 'count': e.value},
        ],
    };

void main() {
  late _MockApi api;
  late ProviderContainer container;

  setUp(() {
    api = _MockApi();
    container = ProviderContainer(
      overrides: [
        republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<FeedController> load(Map<String, dynamic> post) async {
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'data': [post],
        'nextCursor': null,
      },
    );
    final sub = container.listen(feedControllerProvider(null), (_, __) {});
    addTearDown(sub.close);
    await container.read(feedControllerProvider(null).future);
    return container.read(feedControllerProvider(null).notifier);
  }

  Post only() =>
      container.read(feedControllerProvider(null)).requireValue.posts.single;

  group('reactions', () {
    test('the web names are read, and an old like becomes a like', () {
      expect(
        Post.fromJson(_post(mine: 'love')).myReaction,
        ReactionType.love,
      );
      expect(
        Post.fromJson(_post(liked: true)).myReaction,
        ReactionType.like,
      );
      expect(Post.fromJson(_post()).myReaction, isNull);
      expect(Post.fromJson(_post(mine: 'nonsense')).myReaction, isNull);
    });

    test('the first reaction adds one, changing it does not', () async {
      final c = await load(_post(likes: 5));
      when(() => api.post(any(), any())).thenAnswer((_) async => {});

      expect(await c.react('1', ReactionType.love), isTrue);
      expect(only().myReaction, ReactionType.love);
      expect(only().likesCount, 6);

      expect(await c.react('1', ReactionType.wow), isTrue);
      expect(only().myReaction, ReactionType.wow);
      expect(only().likesCount, 6);

      expect(await c.react('1', null), isTrue);
      expect(only().myReaction, isNull);
      expect(only().likesCount, 5);

      verify(
        () => api.post(ApiEndpoints.feedReaction('1'), {'type': 'love'}),
      ).called(1);
      verify(
        () => api.post(ApiEndpoints.feedReaction('1'), {'type': null}),
      ).called(1);
    });

    test('the counts of each reaction are read, most chosen first', () {
      final post = Post.fromJson(
        _post(likes: 6, counts: {'like': 3, 'love': 2, 'haha': 1, 'wow': 0}),
      );
      expect(post.reactionCounts, const [
        ReactionCount(ReactionType.like, 3),
        ReactionCount(ReactionType.love, 2),
        ReactionCount(ReactionType.haha, 1),
        ReactionCount(ReactionType.wow, 0),
      ]);
      expect(
        post.topReactions,
        [ReactionType.like, ReactionType.love, ReactionType.haha],
      );
      // An older server sends no counts: only the viewer's own is known.
      expect(Post.fromJson(_post(likes: 4)).topReactions, isEmpty);
      expect(
        Post.fromJson(_post(likes: 4, mine: 'sad')).topReactions,
        [ReactionType.sad],
      );
    });

    test('reacting moves one count between reactions at once', () async {
      final c = await load(_post(likes: 2, counts: {'love': 2}));
      when(() => api.post(any(), any())).thenAnswer((_) async => {});

      await c.react('1', ReactionType.like);
      expect(only().reactionCounts, const [
        ReactionCount(ReactionType.love, 2),
        ReactionCount(ReactionType.like, 1),
      ]);

      await c.react('1', ReactionType.love);
      expect(only().reactionCounts, const [
        ReactionCount(ReactionType.love, 3),
      ]);
      expect(only().likesCount, 3);

      await c.react('1', null);
      expect(only().reactionCounts, const [
        ReactionCount(ReactionType.love, 2),
      ]);
      expect(only().likesCount, 2);
    });

    test('a refused reaction puts the counts back too', () async {
      final c = await load(
        _post(likes: 2, mine: 'love', counts: {'love': 1, 'like': 1}),
      );
      when(() => api.post(any(), any())).thenThrow(Exception('no'));

      await c.react('1', ReactionType.angry);

      expect(only().reactionCounts, const [
        ReactionCount(ReactionType.love, 1),
        ReactionCount(ReactionType.like, 1),
      ]);
    });

    test('a refused reaction is put back', () async {
      final c = await load(_post(likes: 5, mine: 'love'));
      when(() => api.post(any(), any())).thenThrow(Exception('no'));

      expect(await c.react('1', ReactionType.angry), isFalse);

      expect(only().myReaction, ReactionType.love);
      expect(only().likesCount, 5);
    });

    test('who reacted how is read from the list the API sends', () async {
      when(() => api.get(ApiEndpoints.feedReactions('1'))).thenAnswer(
        (_) async => {
          'data': [
            {'type': 'love', 'count': 3},
            {'type': 'mystery', 'count': 9},
            {'type': 'like', 'count': 1},
          ],
        },
      );

      final list = await RepublicRepository(api).reactions('1');

      final types = [for (final r in list) r.type];

      expect(types, [ReactionType.love, ReactionType.like]);
      expect(list.first.count, 3);
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        );

    List<String> photos(int n) => [
          for (var i = 0; i < n; i++) 'https://x.test/$i.jpg',
        ];

    for (final n in [1, 2, 3, 4]) {
      testWidgets('$n photos are all shown', (tester) async {
        await pump(tester, PostMedia(urls: photos(n)));

        expect(find.byType(NetworkImageBox), findsNWidgets(n));
      });
    }

    testWidgets('five or more show how many are hidden', (tester) async {
      await pump(tester, PostMedia(urls: photos(7)));

      expect(find.byType(NetworkImageBox), findsNWidgets(4));
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('a video is a play tile, not an image', (tester) async {
      await pump(
        tester,
        const PostMedia(urls: ['https://x.test/a.mp4?x=1', 'https://x/b.jpg']),
      );

      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
      expect(find.byType(NetworkImageBox), findsOneWidget);
      expect(isVideoUrl('https://x.test/A.MOV'), isTrue);
      expect(isVideoUrl('https://x.test/a.png'), isFalse);
    });

    testWidgets('the viewer opens on the photo tapped and says which', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaViewer(urls: photos(3), initialIndex: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('the summary stacks the reactions the post has, not a heart', (
      tester,
    ) async {
      final post = Post.fromJson(
        _post(likes: 4, mine: 'like', counts: {'like': 3, 'love': 1}),
      );
      await pump(
        tester,
        PostCard(post: post, onLike: () {}, onComments: () {}),
      );

      final stack = tester.widget<ReactionStack>(find.byType(ReactionStack));
      expect(stack.reactions, [ReactionType.like, ReactionType.love]);
      expect(find.byKey(const ValueKey('reaction-like')), findsOneWidget);
      expect(find.byKey(const ValueKey('reaction-love')), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('Like shows the reaction chosen, and the picker has six', (
      tester,
    ) async {
      final post = Post.fromJson(_post(likes: 2, mine: 'haha'));
      ReactionType? picked;
      await pump(
        tester,
        PostCard(
          post: post,
          onLike: () {},
          onComments: () {},
          onReact: (r) => picked = r,
        ),
      );

      expect(find.text('Haha'), findsOneWidget);
      expect(find.text('😂'), findsWidgets);

      await tester.longPress(find.text('Haha'));
      await tester.pumpAndSettle();
      for (final r in ReactionType.values) {
        expect(find.text(r.emoji), findsWidgets, reason: r.name);
      }

      await tester.tap(find.text('😮').last);
      await tester.pumpAndSettle();
      expect(picked, ReactionType.wow);
    });
  });
}
