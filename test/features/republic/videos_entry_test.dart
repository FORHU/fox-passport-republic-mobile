import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/reel_player.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/features/republic/presentation/pages/videos_page.dart';
import 'package:flutter_template/features/republic/presentation/widgets/feed_video.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/features/republic/presentation/widgets/videos_shelf.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';

class _MockApi extends Mock implements ApiService {}

/// A player that plays nothing: it is ready at once.
class _FakePlayer extends VideoPlayerController {
  _FakePlayer(this.url) : super.networkUrl(Uri.parse(url));

  final String url;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      size: const Size(720, 1280),
      duration: const Duration(seconds: 30),
    );
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  // The real one tells the platform to let go of a texture there is not.
  // ignore: must_call_super
  Future<void> dispose() async => disposed = true;
}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

Map<String, dynamic> _post(String id, String name, {String? media}) => {
      'id': id,
      'author': {'id': 'u$id', 'name': name},
      'content': 'Post $id',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'tab': 'community',
      'mediaUrls': [if (media != null) media],
      'likesCount': 0,
      'commentsCount': 0,
    };

Post _video(String id, String name) => Post.fromJson(
      _post(id, name, media: 'https://cdn.test/$id.mp4'),
    );

void main() {
  group('the Videos shelf', () {
    Future<void> show(
      WidgetTester tester,
      List<Post> posts, {
      ValueChanged<Post>? onOpen,
      VoidCallback? onSeeAll,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: VideosShelf(
                posts: posts,
                onOpen: onOpen ?? (_) {},
                onSeeAll: onSeeAll ?? () {},
              ),
            ),
          ),
        );

    testWidgets('has a tile for each video, and none for other posts', (
      tester,
    ) async {
      await show(tester, [
        _video('1', 'Ada'),
        Post.fromJson(_post('2', 'Ben')),
        Post.fromJson(_post('3', 'Cy', media: 'https://cdn.test/p.jpg')),
        _video('4', 'Dee'),
      ]);

      expect(find.text('Reels'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Dee'), findsOneWidget);
      expect(find.text('Ben'), findsNothing);
      expect(find.text('Cy'), findsNothing);
    });

    testWidgets('takes no room when there is no video', (tester) async {
      await show(tester, [Post.fromJson(_post('2', 'Ben'))]);

      expect(find.text('Reels'), findsNothing);
      expect(tester.getSize(find.byType(VideosShelf)).height, 0);
    });

    testWidgets('a tile opens that video, and See all opens the videos', (
      tester,
    ) async {
      Post? opened;
      var all = 0;
      await show(
        tester,
        [_video('1', 'Ada'), _video('4', 'Dee')],
        onOpen: (p) => opened = p,
        onSeeAll: () => all++,
      );

      await tester.tap(find.text('Dee'));
      expect(opened?.id, '4');

      await tester.tap(find.text('See all'));
      expect(all, 1);
    });

    testWidgets('shows at most ten tiles', (tester) async {
      await show(tester, [
        for (var i = 0; i < 14; i++) _video('$i', 'Foxer $i'),
      ]);

      expect(
        find.byType(InkWell).evaluate().length,
        lessThanOrEqualTo(10 + 1), // the ten tiles and the See all button
      );
    });

    testWidgets('a tile is a vertical 9:16', (tester) async {
      await show(tester, [_video('1', 'Ada')]);

      final tile = tester.getSize(find.byType(ClipRRect).first);
      expect(tile.height / tile.width, closeTo(16 / 9, 0.02));
    });
  });

  group('the Republic', () {
    late _MockApi api;
    final created = <_FakePlayer>[];

    Future<void> open(
      WidgetTester tester,
      List<Map<String, dynamic>> posts,
    ) async {
      api = _MockApi();
      created.clear();
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {'data': posts, 'nextCursor': null},
      );
      tester.view
        ..physicalSize = const Size(900, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(_Session.new),
            reelPlayerFactoryProvider.overrideWithValue((url) {
              final player = _FakePlayer(url);
              created.add(player);
              return player;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RepublicPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final posts = [
      _post('1', 'Ada', media: 'https://cdn.test/1.mp4'),
      _post('2', 'Ben'),
      _post('3', 'Cy', media: 'https://cdn.test/3.mp4'),
    ];

    Finder inVideos(Finder what) =>
        find.descendant(of: find.byType(VideosPage), matching: what);

    testWidgets('lists the videos in a shelf under the composer', (
      tester,
    ) async {
      await open(tester, posts);

      expect(find.byType(VideosShelf), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('has no shelf when nobody has posted a video', (tester) async {
      await open(tester, [_post('2', 'Ben')]);

      expect(find.text('See all'), findsNothing);
    });

    testWidgets('starts on Posts, with a Posts | Videos switch', (
      tester,
    ) async {
      await open(tester, posts);

      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('Reels'), findsWidgets);
      expect(find.byType(VideosPage), findsNothing);
      expect(find.byType(PostCard), findsWidgets);
    });

    testWidgets('a tile opens the Reels view at that video', (tester) async {
      await open(tester, posts);

      await tester.tap(
        find.descendant(
          of: find.byType(VideosShelf),
          matching: find.text('Cy'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VideosPage), findsOneWidget);
      expect(inVideos(find.text('Cy')), findsOneWidget);
      expect(inVideos(find.text('Ada')), findsNothing);
    });

    testWidgets('See all and the switch open Videos, Posts comes back', (
      tester,
    ) async {
      await open(tester, posts);

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(inVideos(find.text('Ada')), findsOneWidget);

      await tester.tap(find.text('Posts'));
      await tester.pumpAndSettle();
      expect(find.byType(VideosPage), findsNothing);

      await tester.tap(find.text('Reels').last);
      await tester.pumpAndSettle();
      expect(find.byType(VideosPage), findsOneWidget);
    });

    testWidgets('swiping sideways changes view', (tester) async {
      await open(tester, posts);

      await tester.fling(
        find.byType(PageView).first,
        const Offset(-600, 0),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(VideosPage), findsOneWidget);

      await tester.fling(find.byType(VideosPage), const Offset(600, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.byType(VideosPage), findsNothing);
    });

    testWidgets('the video inside a post opens the Videos view at it', (
      tester,
    ) async {
      await open(tester, posts);

      await tester.tap(
        find.descendant(
          of: find.byType(PostCard).first,
          matching: find.byType(FeedVideo),
        ),
      );
      await tester.pumpAndSettle();

      expect(inVideos(find.text('Ada')), findsOneWidget);
    });

    testWidgets('a video in the feed plays by itself, one at a time', (
      tester,
    ) async {
      await open(tester, posts);

      final live = created.where((p) => !p.disposed).toList();
      expect(live, hasLength(1));
      expect(live.single.url, 'https://cdn.test/1.mp4');
      expect(live.single.value.isPlaying, isTrue);
      expect(live.single.value.volume, isNotNull);
    });

    testWidgets('the feed video stops when the Videos view opens', (
      tester,
    ) async {
      await open(tester, posts);
      final feedPlayer = created.firstWhere((p) => !p.disposed);

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(feedPlayer.disposed, isTrue);
    });

    testWidgets('tapping the video in the feed opens it in Videos', (
      tester,
    ) async {
      await open(tester, posts);

      await tester.tap(find.byType(FeedVideo).last);
      await tester.pumpAndSettle();

      expect(inVideos(find.text('Cy')), findsOneWidget);
    });

    for (final width in [320.0, 360.0, 412.0]) {
      testWidgets('the Reels buttons clear the pill and the edge at $width', (
        tester,
      ) async {
        await open(tester, posts);
        tester.view
          ..physicalSize = Size(width, 2400)
          ..devicePixelRatio = 1;
        await tester.pumpAndSettle();

        await tester.tap(find.text('See all'));
        await tester.pumpAndSettle();

        // The pill's labels with its padding ('Reels' is also the shelf title).
        final pill = tester
            .getRect(find.text('Posts'))
            .expandToInclude(tester.getRect(find.text('Reels').last))
            .inflate(3);
        final post = tester.getRect(find.byTooltip('Post a reel'));
        final sound = tester.getRect(find.byTooltip('Turn sound on'));

        expect(post.left, greaterThanOrEqualTo(pill.right));
        expect(sound.left - post.right, greaterThanOrEqualTo(8));
        expect(width - sound.right, greaterThanOrEqualTo(12));
      });
    }

    testWidgets('the shelf steps aside while searching', (tester) async {
      await open(tester, posts);

      await tester.tap(find.byTooltip('Search the Republic'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'wedding');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(VideosShelf), findsNothing);
    });
  });
}
