import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/media_picker.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/new_post.dart';
import 'package:flutter_template/features/republic/presentation/pages/compose_post_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FakePicker implements MediaPicker {
  @override
  Future<List<PickedMedia>> pickMany(int limit) async => [
        PickedMedia(bytes: Uint8List(0), name: 'a.jpg'),
      ];
}

class _Session extends AuthController {
  _Session([this.roles = const []]);

  final List<String> roles;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'me',
          email: 'a@b.co',
          name: 'Ada',
          roleType: roles,
        ),
      );
}

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, Object?>{});
  });

  group('NewPost', () {
    test('a story is sent without a poll or a venue, and without a tab', () {
      const post = NewPost(type: ComposeType.story, content: ' Hello ');

      expect(post.toJson(), {
        'type': 'citizen_experience',
        'content': 'Hello',
        'mediaUrls': <String>[],
        'visibility': 'public',
      });
    });

    test('a poll carries its options, a spotlight its venue', () {
      const poll = NewPost(
        type: ComposeType.poll,
        content: 'Which?',
        pollOptions: ['A', 'B'],
        visibility: PostVisibility.followers,
      );
      const spot = NewPost(
        type: ComposeType.venueSpotlight,
        content: 'Come',
        venueId: 'v1',
        visibility: PostVisibility.onlyMe,
      );

      expect(poll.toJson()['pollOptions'], ['A', 'B']);
      expect(poll.toJson()['visibility'], 'followers');
      expect(spot.toJson()['venueId'], 'v1');
      expect(spot.toJson()['visibility'], 'only_me');
      expect(spot.toJson().containsKey('pollOptions'), isFalse);
    });

    test('an @ at the cursor is found, anywhere else is not', () {
      expect(mentionQueryAt('hi @ma'), 'ma');
      expect(mentionQueryAt('@'), '');
      expect(mentionQueryAt('hi @ma and'), isNull);
      expect(mentionQueryAt('mail me@ma'), isNull);
    });
  });

  group('requests', () {
    test('posting, uploading, mentions and my venues', () async {
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'file': {'url': 'https://x.test/a.jpg'},
        },
      );
      when(
        () => api.get(
          ApiEndpoints.feedMentionSearch,
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': [
            {'id': 'u1', 'name': 'Maria', 'username': 'maria'},
            {'name': 'no id'},
          ],
        },
      );
      when(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'venues': [
            {'id': 'v1', 'name': 'Sky Hall'},
          ],
        },
      );
      final repo = RepublicRepository(api);

      expect(
        await repo.uploadMedia(PickedMedia(bytes: Uint8List(1), name: 'a.jpg')),
        'https://x.test/a.jpg',
      );
      final people = await repo.mentionCandidates('ma');
      final venues = await repo.myVenues('me');
      await repo.createPost(
        const NewPost(type: ComposeType.story, content: 'Hi'),
      );

      expect(people.single.handle, 'maria');
      expect(venues.single.name, 'Sky Hall');
      verify(
        () => api.get(
          ApiEndpoints.venues,
          query: {'hostId': 'me', 'limit': 100},
        ),
      ).called(1);
      verify(() => api.post(ApiEndpoints.feed, any())).called(1);
    });
  });

  group('the page', () {
    Future<void> open(
      WidgetTester tester, {
      List<String> roles = const [],
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(() => _Session(roles)),
            mediaPickerProvider.overrideWithValue(_FakePicker()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ComposePostPage(),
          ),
        ),
      );
      await tester.pump();
    }

    ElevatedButton postButton(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton));

    testWidgets('Post waits for some words or a photo', (tester) async {
      await open(tester);
      expect(postButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tester.pump();
      expect(postButton(tester).onPressed, isNotNull);
    });

    testWidgets('a photo alone is enough, and it is uploaded then attached', (
      tester,
    ) async {
      when(() => api.post(ApiEndpoints.uploadFile, any())).thenAnswer(
        (_) async => {
          'file': {'url': 'https://x.test/a.jpg'},
        },
      );
      when(() => api.post(ApiEndpoints.feed, any()))
          .thenAnswer((_) async => {});
      await open(tester);

      await tester.tap(find.text('Add photos'));
      await tester.pump();
      await tester.pump();
      expect(find.text('1 of 10 photos'), findsOneWidget);
      expect(postButton(tester).onPressed, isNotNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump();

      final sent = verify(() => api.post(ApiEndpoints.feed, captureAny()))
          .captured
          .single as Map<String, Object?>;
      expect(sent['mediaUrls'], ['https://x.test/a.jpg']);
    });

    testWidgets('a poll needs two different options', (tester) async {
      await open(tester);
      await tester.tap(find.text('Poll'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Which?');
      await tester.pump();
      expect(postButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(1), 'Pizza');
      await tester.enterText(find.byType(TextField).at(2), 'pizza');
      await tester.pump();
      expect(postButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(2), 'Tacos');
      await tester.pump();
      expect(postButton(tester).onPressed, isNotNull);
    });

    testWidgets('a citizen is not offered Spotlight venue', (tester) async {
      await open(tester);

      expect(find.text('Spotlight venue'), findsNothing);
    });

    testWidgets('a venue foxer is, and says when there is no venue', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .thenAnswer((_) async => {'venues': <Object>[]});
      await open(tester, roles: ['venueFoxer']);

      await tester.tap(find.text('Spotlight venue'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text("You don't have a venue to spotlight yet."),
        findsOneWidget,
      );
    });

    testWidgets('typing @ suggests people and choosing one fills the name', (
      tester,
    ) async {
      when(
        () => api.get(
          ApiEndpoints.feedMentionSearch,
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': [
            {'id': 'u1', 'name': 'Maria Santos', 'username': 'maria'},
          ],
        },
      );
      await open(tester);

      await tester.enterText(find.byType(TextField).first, 'hi @ma');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Maria Santos'), findsOneWidget);

      await tester.tap(find.text('Maria Santos'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'hi @maria ',
      );
    });
  });
}
