import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/features/republic/presentation/widgets/videos_shelf.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

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

      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Dee'), findsOneWidget);
      expect(find.text('Ben'), findsNothing);
      expect(find.text('Cy'), findsNothing);
    });

    testWidgets('takes no room when there is no video', (tester) async {
      await show(tester, [Post.fromJson(_post('2', 'Ben'))]);

      expect(find.text('Videos'), findsNothing);
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
    late GoRouter router;
    String? lastLocation;

    Future<void> open(
      WidgetTester tester,
      List<Map<String, dynamic>> posts,
    ) async {
      api = _MockApi();
      lastLocation = null;
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {'data': posts, 'nextCursor': null},
      );
      tester.view
        ..physicalSize = const Size(900, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const RepublicPage()),
          GoRoute(
            path: RouteNames.republicVideos,
            builder: (_, state) {
              lastLocation = state.uri.toString();
              return const Scaffold(body: Text('VIDEOS PAGE'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(_Session.new),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('a tile opens the videos page at that video', (tester) async {
      await open(tester, posts);

      await tester.tap(
        find.descendant(
          of: find.byType(VideosShelf),
          matching: find.text('Cy'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIDEOS PAGE'), findsOneWidget);
      expect(lastLocation, '/republic/videos?post=3');
    });

    testWidgets('See all and the header button open the videos', (
      tester,
    ) async {
      await open(tester, posts);

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(lastLocation, '/republic/videos');

      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Videos'));
      await tester.pumpAndSettle();
      expect(lastLocation, '/republic/videos');
    });

    testWidgets('the video inside a post opens the videos page at it', (
      tester,
    ) async {
      await open(tester, posts);

      await tester.tap(
        find.descendant(
          of: find.byType(PostCard).first,
          matching: find.byIcon(Icons.play_circle_fill_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIDEOS PAGE'), findsOneWidget);
      expect(lastLocation, '/republic/videos?post=1');
    });

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
