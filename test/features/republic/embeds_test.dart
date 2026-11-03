import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _poll({
  int a = 3,
  int b = 1,
  List<String> aVoters = const [],
}) =>
    {
      'id': 'poll1',
      'options': [
        {
          'id': 'oa',
          'label': 'Pizza',
          'votesCount': a,
          'votes': [
            for (final u in aVoters) {'userId': u},
          ],
        },
        {'id': 'ob', 'label': 'Tacos', 'votesCount': b, 'votes': <Object>[]},
      ],
    };

Map<String, dynamic> _post(
  String type, [
  Map<String, dynamic> extra = const {},
]) =>
    {
      'id': 'p1',
      'type': type,
      'content': 'Hello @maria and friends',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': 'someone', 'name': 'Bea'},
      ...extra,
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

  group('reading a post', () {
    test('a poll, with the option a person picked', () {
      final post = Post.fromJson(
        _post('poll', {
          'poll': _poll(aVoters: ['me']),
        }),
      );

      expect(post.poll!.totalVotes, 4);
      expect(post.poll!.pickedBy('me'), 'oa');
      expect(post.poll!.pickedBy('someone else'), isNull);
      expect(post.poll!.pickedBy(null), isNull);
    });

    test('each marketplace type reads its own listing as a catalog row', () {
      Post read(String type, String key, Map<String, dynamic> row) =>
          Post.fromJson(_post(type, {key: row}));

      final venue = read('venue_spotlight', 'venue', {
        'id': 'v1',
        'name': 'Sky Hall',
        'city': 'Baguio',
        'capacity': 80,
        'price': '25000',
        'billingRate': 'daily',
      });
      final gear = read('gear_offering', 'asset', {'id': 'a1', 'name': 'PA'});
      final service =
          read('service_offering', 'service', {'id': 's1', 'name': 'DJ'});
      final event = read('event_announcement', 'event', {
        'id': 'e1',
        'name': 'Bonfire',
        'startAt': '2099-01-01T10:00:00.000Z',
      });

      expect(venue.listing!.kind, CatalogKind.venues);
      expect(venue.listing!.price, 25000);
      expect(venue.listing!.capacity, 80);
      expect(gear.listing!.kind, CatalogKind.gear);
      expect(service.listing!.kind, CatalogKind.services);
      expect(event.listing!.kind, CatalogKind.events);
      expect(event.listing!.eventStartAt, isNotNull);
    });

    test('a story has no listing, and a missing row is no listing', () {
      expect(Post.fromJson(_post('citizen_experience')).listing, isNull);
      expect(Post.fromJson(_post('venue_spotlight')).listing, isNull);
    });

    test('review, stamp and repost', () {
      final post = Post.fromJson(
        _post('review_share', {
          'isPinned': true,
          'review': {'rating': 9, 'comment': ' Great '},
          'stamp': {
            'eventName': 'Night',
            'venue': {'name': 'Sky Hall', 'city': 'Baguio'},
          },
          'originalPost': {
            'id': 'o1',
            'content': 'Original',
            'mediaUrls': ['https://x.test/a.jpg'],
            'author': {'id': 'u', 'name': 'Maria'},
          },
        }),
      );

      expect(post.isPinned, isTrue);
      expect(post.review!.rating, 5);
      expect(post.review!.comment, 'Great');
      expect(post.stamp!.venueName, 'Sky Hall');
      expect(post.stamp!.city, 'Baguio');
      expect(post.original!.authorName, 'Maria');
      expect(post.original!.imageUrl, 'https://x.test/a.jpg');
    });
  });

  group('voting', () {
    test('the vote goes to the poll and the new tally replaces the old',
        () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': [
            _post('poll', {'poll': _poll()}),
          ],
          'nextCursor': null,
        },
      );
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': _poll(a: 4, aVoters: ['me']),
        },
      );
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);

      final ok = await container
          .read(feedControllerProvider(null).notifier)
          .vote('p1', 'oa');

      final poll = container
          .read(feedControllerProvider(null))
          .requireValue
          .posts
          .single
          .poll!;
      expect(ok, isTrue);
      expect(poll.totalVotes, 5);
      expect(poll.pickedBy('me'), 'oa');
      verify(
        () => api.post(ApiEndpoints.feedPollVote('p1'), {'optionId': 'oa'}),
      ).called(1);
    });

    test('a refused vote changes nothing', () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': [
            _post('poll', {'poll': _poll()}),
          ],
          'nextCursor': null,
        },
      );
      when(() => api.post(any(), any())).thenThrow(Exception('no'));
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);

      final ok = await container
          .read(feedControllerProvider(null).notifier)
          .vote('p1', 'oa');

      expect(ok, isFalse);
      expect(
        container
            .read(feedControllerProvider(null))
            .requireValue
            .posts
            .single
            .poll!
            .totalVotes,
        4,
      );
    });
  });

  group('the card', () {
    Future<void> pump(WidgetTester tester, PostCard card) => tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SingleChildScrollView(child: card)),
            ),
          ),
        );

    PostCard card(
      Post post, {
      ValueChanged<String>? onVote,
      VoidCallback? onOpenListing,
      VoidCallback? onMessage,
    }) =>
        PostCard(
          post: post,
          onLike: () {},
          onComments: () {},
          myUserId: 'me',
          onVote: onVote,
          onOpenListing: onOpenListing,
          onMessage: onMessage,
        );

    testWidgets('a poll shows shares and sends the option tapped', (
      tester,
    ) async {
      String? voted;
      await pump(
        tester,
        card(
          Post.fromJson(_post('poll', {'poll': _poll()})),
          onVote: (o) => voted = o,
        ),
      );

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('4 votes'), findsOneWidget);

      await tester.tap(find.text('Tacos'));
      expect(voted, 'ob');
    });

    testWidgets('a venue spotlight says Book venue and can message', (
      tester,
    ) async {
      var opened = false;
      var messaged = false;
      await pump(
        tester,
        card(
          Post.fromJson(
            _post('venue_spotlight', {
              'venue': {'id': 'v1', 'name': 'Sky Hall', 'city': 'Baguio'},
            }),
          ),
          onOpenListing: () => opened = true,
          onMessage: () => messaged = true,
        ),
      );

      expect(find.text('Sky Hall'), findsOneWidget);
      await tester.tap(find.text('Book venue'));
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded).first);

      expect(opened, isTrue);
      expect(messaged, isTrue);
    });

    for (final (type, key, label) in [
      ('gear_offering', 'asset', 'Rent gear'),
      ('service_offering', 'service', 'Book service'),
      ('event_announcement', 'event', 'Get tickets'),
    ]) {
      testWidgets('$type says $label', (tester) async {
        await pump(
          tester,
          card(
            Post.fromJson(
              _post(type, {
                key: {'id': '1', 'name': 'Thing'},
              }),
            ),
          ),
        );

        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('a partner post offers to contact, a review shows stars', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          Post.fromJson(
            _post('partner_announcement', {
              'review': {'rating': 4},
            }),
          ),
          onMessage: () {},
        ),
      );

      expect(find.text('Contact partner'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    });

    testWidgets('pinned, stamped and quoted posts say so', (tester) async {
      await pump(
        tester,
        card(
          Post.fromJson(
            _post('citizen_experience', {
              'isPinned': true,
              'stamp': {'eventName': 'Night'},
              'originalPost': {
                'id': 'o1',
                'content': 'The original',
                'author': {'id': 'u', 'name': 'Maria'},
              },
            }),
          ),
        ),
      );

      expect(find.text('Featured in Republic'), findsOneWidget);
      expect(find.textContaining('Verified Venue Stamp'), findsOneWidget);
      expect(find.text('The original'), findsOneWidget);
    });

    testWidgets('a plain story shows nothing extra', (tester) async {
      await pump(tester, card(Post.fromJson(_post('citizen_experience'))));

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text('Featured in Republic'), findsNothing);
      expect(find.textContaining('vote'), findsNothing);
    });
  });
}
