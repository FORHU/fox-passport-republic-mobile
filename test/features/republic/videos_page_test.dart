import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/reel_player.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/videos_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

/// A player that plays nothing: it is ready at once and remembers what it was
/// told.
class _FakePlayer extends VideoPlayerController {
  _FakePlayer(String url) : super.networkUrl(Uri.parse(url));

  bool playing = false;
  double volume = 1;
  bool looping = false;
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
  Future<void> play() async {
    playing = true;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    playing = false;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> setLooping(bool looping) async => this.looping = looping;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  // The real one tells the platform to let go of a texture there is not.
  // ignore: must_call_super
  Future<void> dispose() async => disposed = true;
}

Map<String, dynamic> _post(
  String id,
  String name, {
  String? media,
  String content = '',
  int likes = 0,
}) =>
    {
      'id': id,
      'author': {'id': 'u$id', 'name': name},
      'content': content,
      'createdAt': '2026-11-04T10:00:00.000Z',
      'tab': 'community',
      'mediaUrls': [if (media != null) media],
      'likesCount': likes,
      'commentsCount': 2,
    };

void main() {
  late _MockApi api;
  late Map<String, _FakePlayer> players;

  setUp(() {
    api = _MockApi();
    players = {};
  });

  Future<void> open(
    WidgetTester tester,
    List<Map<String, dynamic>> posts, {
    String? nextCursor,
    String? initialPostId,
    VoidCallback? onPost,
  }) async {
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {'data': posts, 'nextCursor': nextCursor},
    );
    tester.view
      ..physicalSize = const Size(720, 1280)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
          authControllerProvider.overrideWith(_Session.new),
          reelPlayerFactoryProvider.overrideWithValue(
            (url) => players.putIfAbsent(url, () => _FakePlayer(url)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VideosPage(initialPostId: initialPostId, onPost: onPost),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final feed = [
    _post('1', 'Ada', media: 'https://cdn.test/a.mp4', content: 'First clip'),
    _post('2', 'Ben', content: 'Only words'),
    _post('3', 'Cy', media: 'https://cdn.test/photo.jpg'),
    _post('4', 'Dee', media: 'https://cdn.test/b.mp4', content: 'Second clip'),
    _post('5', 'Eli', media: 'https://cdn.test/c.mp4', likes: 7),
  ];

  group('post videos', () {
    test('finds the first video and the poster the server keeps beside it', () {
      final post = Post.fromJson(
        _post('1', 'Ada', media: 'https://cdn.test/u/x.mp4?v=1'),
      );
      expect(post.videoUrl, 'https://cdn.test/u/x.mp4?v=1');
      expect(post.posterUrl, 'https://cdn.test/u/x.jpg');
    });

    test('a photo or words alone are not a video', () {
      expect(Post.fromJson(_post('1', 'A')).videoUrl, isNull);
      expect(
        Post.fromJson(_post('1', 'A', media: 'https://cdn.test/p.jpg'))
            .videoUrl,
        isNull,
      );
    });

    test('a video that is not an optimized .mp4 has no poster', () {
      final post = Post.fromJson(
        _post('1', 'A', media: 'https://cdn.test/clip.mov'),
      );
      expect(post.videoUrl, isNotNull);
      expect(post.posterUrl, isNull);
    });
  });

  group('the Videos page', () {
    testWidgets('shows only the posts that have a video, one to a screen', (
      tester,
    ) async {
      await open(tester, feed);

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('First clip'), findsOneWidget);
      // The words-only and photo posts are not here.
      expect(find.text('Ben'), findsNothing);
      expect(find.text('Cy'), findsNothing);
      // One screen at a time.
      expect(find.text('Dee'), findsNothing);
    });

    testWidgets('plays the one on screen, muted and looping', (tester) async {
      await open(tester, feed);

      final first = players['https://cdn.test/a.mp4']!;
      expect(first.playing, isTrue);
      expect(first.looping, isTrue);
      expect(first.volume, 0);
    });

    testWidgets('gets the next video ready and plays it after a swipe', (
      tester,
    ) async {
      await open(tester, feed);
      final first = players['https://cdn.test/a.mp4']!;
      // The next is prepared ahead, but held.
      final second = players['https://cdn.test/b.mp4']!;
      expect(second.playing, isFalse);

      await tester.fling(find.text('First clip'), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Dee'), findsOneWidget);
      expect(second.playing, isTrue);
      expect(first.playing, isFalse);
    });

    testWidgets('opens at the video it was asked for, and plays that one', (
      tester,
    ) async {
      await open(tester, feed, initialPostId: '4');

      expect(find.text('Dee'), findsOneWidget);
      expect(find.text('Second clip'), findsOneWidget);
      expect(players['https://cdn.test/b.mp4']!.playing, isTrue);
      // The one it skipped is not playing.
      expect(players['https://cdn.test/a.mp4']?.playing ?? false, isFalse);
    });

    testWidgets('opens at the first when the video is not in the feed', (
      tester,
    ) async {
      await open(tester, feed, initialPostId: 'gone');

      expect(find.text('Ada'), findsOneWidget);
      expect(players['https://cdn.test/a.mp4']!.playing, isTrue);
    });

    testWidgets('lets go of a video that is two screens behind', (
      tester,
    ) async {
      await open(tester, feed);
      final first = players['https://cdn.test/a.mp4']!;

      await tester.fling(find.text('First clip'), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();
      await tester.fling(find.text('Second clip'), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Eli'), findsOneWidget);
      expect(first.disposed, isTrue);
    });

    testWidgets('a tap pauses it and another plays it again', (tester) async {
      await open(tester, feed);
      final first = players['https://cdn.test/a.mp4']!;

      await tester.tapAt(const Offset(360, 500));
      await tester.pump();
      expect(first.playing, isFalse);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tapAt(const Offset(360, 500));
      await tester.pump();
      expect(first.playing, isTrue);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('the sound button turns sound on and off', (tester) async {
      await open(tester, feed);
      final first = players['https://cdn.test/a.mp4']!;

      await tester.tap(find.byTooltip('Turn sound on'));
      await tester.pump();
      expect(first.volume, 1);
      expect(find.byTooltip('Turn sound off'), findsOneWidget);

      await tester.tap(find.byTooltip('Turn sound off'));
      await tester.pump();
      expect(first.volume, 0);
    });

    testWidgets('has the like count, comments and share down the side', (
      tester,
    ) async {
      await open(tester, feed);

      expect(find.byTooltip('Like'), findsOneWidget);
      expect(find.byTooltip('Comments'), findsOneWidget);
      expect(find.byTooltip('Share'), findsOneWidget);
      expect(find.byTooltip('More'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('says so when there are no videos', (tester) async {
      await open(tester, [_post('2', 'Ben', content: 'Only words')]);

      expect(find.text('No reels yet'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('has a button to post a video, when it can', (tester) async {
      var posted = 0;
      await open(tester, feed, onPost: () => posted++);

      await tester.tap(find.byTooltip('Post a reel'));

      expect(posted, 1);
    });

    testWidgets('has no post button without a way to post', (tester) async {
      await open(tester, feed);

      expect(find.byTooltip('Post a reel'), findsNothing);
    });

    testWidgets('an empty Videos view offers to post the first video', (
      tester,
    ) async {
      var posted = 0;
      await open(
        tester,
        [_post('2', 'Ben', content: 'Only words')],
        onPost: () => posted++,
      );

      await tester.tap(find.text('Post a reel'));

      expect(posted, 1);
    });

    testWidgets('the post and sound buttons stay put as the reels slide', (
      tester,
    ) async {
      await open(tester, feed, onPost: () {});
      final post = tester.getRect(find.byTooltip('Post a reel'));
      final sound = tester.getRect(find.byTooltip('Turn sound on'));

      await tester.fling(find.text('First clip'), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();

      // Still exactly one of each, in the same place, on the next reel.
      expect(find.byTooltip('Post a reel'), findsOneWidget);
      expect(find.byTooltip('Turn sound on'), findsOneWidget);
      expect(tester.getRect(find.byTooltip('Post a reel')), post);
      expect(tester.getRect(find.byTooltip('Turn sound on')), sound);
    });
  });
}
