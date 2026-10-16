import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _post(String id, {int likes = 0, bool liked = false}) => {
      'id': id,
      'content': 'Post $id',
      'tab': 'community',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'likesCount': likes,
      'commentsCount': 0,
      'isLikedByMe': liked,
      'author': {'id': 'u', 'name': 'Maria'},
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

  test('reads a post, its author and the counts', () {
    final post = Post.fromJson({
      ..._post('a', likes: 3, liked: true),
      'author': const {
        'id': 'u',
        'name': ' ',
        'username': 'maria',
        'imgId': 'x.jpg',
      },
      'editedAt': '2026-01-01T00:00:00.000Z',
      'mediaUrls': const ['https://img/1.jpg', ''],
    });
    expect(post.author.name, 'maria');
    expect(post.author.imageUrl, 'x.jpg');
    expect(post.likesCount, 3);
    expect(post.isLikedByMe, isTrue);
    expect(post.edited, isTrue);
    expect(post.mediaUrls, ['https://img/1.jpg']);
  });

  test('loads a page, then appends the next without repeats', () async {
    var call = 0;
    when(() => api.get(any(), query: any(named: 'query')))
        .thenAnswer((_) async {
      call++;
      return call == 1
          ? {
              'data': [_post('1'), _post('2')],
              'nextCursor': '2',
            }
          : {
              'data': [_post('2'), _post('3')],
              'nextCursor': null,
            };
    });

    final sub = container.listen(feedControllerProvider(null), (_, __) {});
    addTearDown(sub.close);
    var state = await container.read(feedControllerProvider(null).future);
    expect(state.posts.map((p) => p.id), ['1', '2']);
    expect(state.hasMore, isTrue);

    await container.read(feedControllerProvider(null).notifier).loadMore();
    state = container.read(feedControllerProvider(null)).requireValue;
    expect(state.posts.map((p) => p.id), ['1', '2', '3']);
    expect(state.hasMore, isFalse);
  });

  test('a like shows at once and is undone when the server refuses', () async {
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'data': [_post('1', likes: 5)],
        'nextCursor': null,
      },
    );
    final sub = container.listen(feedControllerProvider(null), (_, __) {});
    addTearDown(sub.close);
    await container.read(feedControllerProvider(null).future);
    final controller = container.read(feedControllerProvider(null).notifier);

    when(() => api.post(any(), any()))
        .thenAnswer((_) async => {'success': true});
    expect(await controller.toggleLike('1'), isTrue);
    var post =
        container.read(feedControllerProvider(null)).requireValue.posts.single;
    expect(post.isLikedByMe, isTrue);
    expect(post.likesCount, 6);

    when(() => api.post(any(), any())).thenThrow(Exception('nope'));
    expect(await controller.toggleLike('1'), isFalse);
    post =
        container.read(feedControllerProvider(null)).requireValue.posts.single;
    expect(post.isLikedByMe, isTrue);
    expect(post.likesCount, 6);
  });

  testWidgets('the page lists posts and says so when there are none', (
    tester,
  ) async {
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'data': [_post('1'), _post('2')],
        'nextCursor': null,
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepublicPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Republic'), findsOneWidget);
    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Post 2'), findsOneWidget);
    expect(find.text('Maria'), findsNWidgets(2));
  });
}
