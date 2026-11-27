import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/formatting/compact_count.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _json(
  String id, {
  int comments = 0,
  int shares = 0,
  int sends = 0,
  int reposts = 0,
}) =>
    {
      'id': id,
      'content': 'post $id',
      'tab': 'community',
      'commentsCount': comments,
      'sharesCount': shares,
      'sendsCount': sends,
      'repostsCount': reposts,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': 'u', 'name': 'Maria'},
    };

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('reading the counts (app#303)', () {
    test('a post reads its share, send and repost counts', () {
      final post = Post.fromJson(_json('a', shares: 4, sends: 1, reposts: 2));
      expect(post.sharesCount, 4);
      expect(post.sendsCount, 1);
      expect(post.repostsCount, 2);
    });

    test('an older row without them reads as zero', () {
      final post = Post.fromJson(const {
        'id': 'a',
        'content': '',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'author': {'id': 'u', 'name': 'Maria'},
      });
      expect(
        [post.sharesCount, post.sendsCount, post.repostsCount],
        [0, 0, 0],
      );
    });
  });

  group('the activity line', () {
    test('shows only the comments while nothing else has happened', () {
      final post = Post.fromJson(_json('a', comments: 3));
      expect(postActivityLine(l10n, post), '3 comments');
    });

    test('adds reposts, sends and shares, singular or plural', () {
      expect(
        postActivityLine(
          l10n,
          Post.fromJson(_json('a', comments: 3, reposts: 2, sends: 1)),
        ),
        '3 comments · 2 reposts · 1 sent',
      );
      expect(
        postActivityLine(l10n, Post.fromJson(_json('a', shares: 1))),
        '0 comments · 1 share',
      );
    });

    test('big counts are short', () {
      expect(compactCount(950), '950');
      expect(compactCount(1200, locale: 'en'), '1.2K');
      expect(
        postActivityLine(
          l10n,
          Post.fromJson(_json('a', shares: 1500)),
          locale: 'en',
        ),
        '0 comments · 1.5K shares',
      );
    });
  });

  group('counting a share', () {
    late _MockApi api;

    setUp(() => api = _MockApi());

    test('a copied link is counted, and the total read back', () async {
      when(() => api.post(ApiEndpoints.feedShare('a'))).thenAnswer(
        (_) async => {
          'data': {'counted': true, 'sharesCount': 5},
        },
      );
      expect(await RepublicRepository(api).trackShare('a'), 5);
      verify(() => api.post('/feed/a/share')).called(1);
    });

    test('no total in the answer gives null', () async {
      when(() => api.post(any())).thenAnswer((_) async => {'data': null});
      expect(await RepublicRepository(api).trackShare('a'), isNull);
    });

    test('the feed shows the new counts straight away', () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': [_json('a', sends: 1, reposts: 2), _json('b')],
          'nextCursor': null,
        },
      );
      final container = ProviderContainer(
        overrides: [
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
          realtimeServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);

      container.read(feedControllerProvider(null).notifier)
        ..updateShareCounts('a', addSends: 3)
        ..updateShareCounts('a', addReposts: 1)
        ..updateShareCounts('a', sharesCount: 7);

      final posts =
          container.read(feedControllerProvider(null)).requireValue.posts;
      final a = posts.firstWhere((p) => p.id == 'a');
      expect([a.sendsCount, a.repostsCount, a.sharesCount], [4, 3, 7]);
      final b = posts.firstWhere((p) => p.id == 'b');
      expect([b.sendsCount, b.repostsCount, b.sharesCount], [0, 0, 0]);
    });
  });

  testWidgets('the line fits one row on a narrow phone with big numbers', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: Post.fromJson(
                _json(
                  'a',
                  comments: 4321,
                  reposts: 1200,
                  sends: 980,
                  shares: 15000,
                ),
              ),
              onLike: () {},
              onComments: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final line = tester.getRect(find.byKey(const ValueKey('post-activity')));
    expect(line.height, lessThan(30));
    expect(line.right, lessThanOrEqualTo(320));
  });
}
