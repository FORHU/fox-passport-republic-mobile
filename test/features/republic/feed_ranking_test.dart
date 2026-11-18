import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/feed_realtime.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// app#308 on the phone: the feed asks for For you or Recent, keeps the
/// session's start for the "New posts" pill, counts posts announced over the
/// socket, puts them on top on a tap, and labels older posts it brought back.

class _MockApi extends Mock implements ApiService {}

class _FakeConnection implements RealtimeConnection {
  final handlers = <String, void Function(Object?)>{};

  @override
  void on(String event, void Function(Object? data) handler) =>
      handlers[event] = handler;

  @override
  void emit(String event, Object? data) {}

  @override
  void connect() {}

  @override
  void dispose() {}

  void receive(String event, Object? data) => handlers[event]?.call(data);
}

const _anchor = '2026-11-18T12:00:00.000Z';

/// The same instant, whether held as UTC or local time (`==` tells them apart).
Matcher _sameMoment(String iso) => predicate<DateTime?>(
      (d) => d != null && d.isAtSameMomentAs(DateTime.parse(iso)),
      'the same moment as $iso',
    );

Map<String, dynamic> _post(String id, String createdAt, {bool? resurfaced}) => {
      'id': id,
      'content': 'post $id',
      'tab': 'community',
      'createdAt': createdAt,
      'author': {'id': 'u-$id', 'name': 'Maria'},
      if (resurfaced != null) 'resurfaced': resurfaced,
    };

/// The query maps the feed was asked with, in order.
List<Map<String, dynamic>> _feedQueries(_MockApi api) => [
      for (final call in verify(
        () => api.get(ApiEndpoints.feed, query: captureAny(named: 'query')),
      ).captured)
        (call as Map).cast<String, dynamic>(),
    ];

void main() {
  late _MockApi api;
  late _FakeConnection connection;
  late ProviderContainer container;

  setUp(() {
    api = _MockApi();
    connection = _FakeConnection();
    when(() => api.get(ApiEndpoints.feed, query: any(named: 'query')))
        .thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#query] as Map<String, dynamic>? ?? {};
      if (query['mode'] == 'recent') {
        return {
          'data': [
            _post('new2', '2026-11-18T12:02:00.000Z'),
            _post('new1', '2026-11-18T12:01:00.000Z'),
            _post('a', '2026-11-18T11:00:00.000Z'),
          ],
          'nextCursor': null,
        };
      }
      return {
        'data': [
          _post('a', '2026-11-18T11:00:00.000Z'),
          _post('old', '2026-09-01T00:00:00.000Z', resurfaced: true),
        ],
        'nextCursor': 'cursor-1',
        'anchor': _anchor,
      };
    });
    when(() => api.get(ApiEndpoints.feedNewCount, query: any(named: 'query')))
        .thenAnswer(
      (_) async => {
        'data': {'count': 2},
      },
    );
    final service = RealtimeService(
      url: 'http://localhost:6002',
      getTicket: () async => 'ticket',
      factory: (_, __) => connection,
    )..start();
    addTearDown(service.stop);
    container = ProviderContainer(
      overrides: [
        republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
        realtimeServiceProvider.overrideWithValue(service),
        feedNewPollIntervalProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<FeedState> load(String? tab) async {
    final sub = container.listen(feedControllerProvider(tab), (_, __) {});
    addTearDown(sub.close);
    return container.read(feedControllerProvider(tab).future);
  }

  test('asks for For you by default and keeps the session start', () async {
    final state = await load(null);
    expect(_feedQueries(api).single['mode'], 'foryou');
    expect(state.since, _sameMoment(_anchor));
    expect(state.posts.last.resurfaced, isTrue);
  });

  test('switching to Recent reloads newest first', () async {
    await load('community');
    container.read(feedModeProvider.notifier).select(FeedMode.recent);
    final state =
        await container.read(feedControllerProvider('community').future);
    final queries = _feedQueries(api);
    expect(queries.last['mode'], 'recent');
    expect(queries.last['tab'], 'community');
    // Recent's "since" is its newest post.
    expect(state.since, _sameMoment('2026-11-18T12:02:00.000Z'));
  });

  test('the saved list sends no mode and has no pill', () async {
    when(() => api.get(ApiEndpoints.feedSaved, query: any(named: 'query')))
        .thenAnswer(
      (_) async => {
        'data': [_post('s', '2026-11-01T00:00:00.000Z')],
        'nextCursor': null,
      },
    );
    final state = await load(RepublicRepository.savedTab);
    final query = verify(
      () => api.get(ApiEndpoints.feedSaved, query: captureAny(named: 'query')),
    ).captured.single as Map;
    expect(query.containsKey('mode'), isFalse);
    expect(state.since, isNull);
  });

  test('a feed:new on this tab is counted, one request per burst', () async {
    await load('community');
    connection
      ..receive(RealtimeEvents.feedNew, {'tab': 'community'})
      ..receive(RealtimeEvents.feedNew, {'tab': 'community'})
      ..receive(RealtimeEvents.feedNew, {'tab': 'marketplace'});
    await Future<void>.delayed(const Duration(milliseconds: 1700));

    final query = verify(
      () => api.get(
        ApiEndpoints.feedNewCount,
        query: captureAny(named: 'query'),
      ),
    ).captured.single as Map;
    expect(query['since'], _anchor);
    expect(query['tab'], 'community');
    expect(
      container.read(feedControllerProvider('community')).requireValue.newCount,
      2,
    );
  });

  test('a tap on New posts puts only the newer posts on top', () async {
    await load(null);
    await container.read(feedControllerProvider(null).notifier).showNewPosts();
    final state = container.read(feedControllerProvider(null)).requireValue;
    expect(
      state.posts.map((p) => p.id),
      ['new2', 'new1', 'a', 'old'],
    );
    expect(state.newCount, 0);
    expect(state.since, _sameMoment('2026-11-18T12:02:00.000Z'));
    // The session's own list is untouched: no reload of For you.
    expect(_feedQueries(api).where((q) => q['mode'] == 'foryou'), hasLength(1));
  });

  test('pull to refresh starts a new For you session', () async {
    await load(null);
    await container.read(feedControllerProvider(null).notifier).refresh();
    final forYou =
        _feedQueries(api).where((q) => q['mode'] == 'foryou').toList();
    expect(forYou, hasLength(2));
    expect(forYou.every((q) => !q.containsKey('cursor')), isTrue);
  });

  group('post labels', () {
    test('reads the For you flags, and falls back to the pin without them', () {
      final featured = Post.fromJson({
        ..._post('f', _anchor),
        'isPinned': true,
        'isFeatured': true,
      });
      final notFeatured = Post.fromJson({
        ..._post('g', _anchor),
        'isPinned': true,
        'isFeatured': false,
      });
      final recent = Post.fromJson({..._post('h', _anchor), 'isPinned': true});
      expect(featured.showsFeatured, isTrue);
      expect(notFeatured.showsFeatured, isFalse);
      expect(recent.showsFeatured, isTrue);
      expect(Post.fromJson(_post('i', _anchor)).resurfaced, isFalse);
    });

    Future<void> pump(WidgetTester tester, Post post) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PostCard(post: post, onLike: () {}, onComments: () {}),
              ),
            ),
          ),
        );

    testWidgets('an older post brought back says "From earlier"',
        (tester) async {
      await pump(tester, Post.fromJson(_post('o', _anchor, resurfaced: true)));
      expect(find.text('From earlier'), findsOneWidget);
      expect(find.text('Featured in Republic'), findsNothing);
    });

    testWidgets('a pinned post For you did not feature has no banner',
        (tester) async {
      await pump(
        tester,
        Post.fromJson(
          {..._post('p', _anchor), 'isPinned': true, 'isFeatured': false},
        ),
      );
      expect(find.text('Featured in Republic'), findsNothing);
      expect(find.text('From earlier'), findsNothing);
    });
  });
}
