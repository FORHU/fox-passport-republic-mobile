import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/compose_sheet.dart';
import 'package:flutter_template/features/republic/presentation/widgets/share_sheets.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
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

Map<String, dynamic> _chat(
  String id,
  String name, {
  bool inbox = false,
  String status = 'accepted',
}) =>
    {
      'id': id,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'isInbox': inbox,
      'status': status,
      if (inbox)
        'inbox': {'name': name, 'type': 'venue'}
      else
        'otherUser': {'id': 'u$id', 'name': name},
    };

final _post = Post.fromJson(const {
  'id': 'p1',
  'content': 'Come to the bonfire',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'author': {'id': 'a', 'name': 'Bea'},
});

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
  });

  Future<void> pump(WidgetTester tester, Widget home) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(api),
            authControllerProvider.overrideWith(_Session.new),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );

  group('requests', () {
    test('a repost sends the caption, trimmed, even when empty', () async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});
      final repo = RepublicRepository(api);

      await repo.repost('p1', '  nice ');
      await repo.repost('p1', '');

      verify(
        () => api.post(ApiEndpoints.feedRepost('p1'), {'caption': 'nice'}),
      ).called(1);
      verify(
        () => api.post(ApiEndpoints.feedRepost('p1'), {'caption': ''}),
      ).called(1);
    });

    test('a message can carry a shared post', () async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});

      await MessagesRepository(api).sendMessage(
        'c1',
        'look',
        sharedPostId: 'p1',
      );
      await MessagesRepository(api).sendMessage('c1', 'hi');

      verify(
        () => api.post(
          ApiEndpoints.conversationMessages('c1'),
          {'content': 'look', 'sharedPostId': 'p1'},
        ),
      ).called(1);
      verify(
        () => api.post(
          ApiEndpoints.conversationMessages('c1'),
          {'content': 'hi'},
        ),
      ).called(1);
    });

    test('a message reads the post it carries', () {
      final m = ChatMessage.fromJson({
        'id': 'm1',
        'senderId': 'u',
        'content': '',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'sharedPost': {
          'id': 'p1',
          'content': 'Come',
          'mediaUrls': ['https://x.test/a.jpg'],
          'author': {'name': 'Bea'},
        },
      });

      expect(m.sharedPost!.authorName, 'Bea');
      expect(m.sharedPost!.imageUrl, 'https://x.test/a.jpg');
      expect(
        ChatMessage.fromJson({
          'id': 'm2',
          'senderId': 'u',
          'content': 'x',
          'createdAt': '2026-01-01T00:00:00.000Z',
        }).sharedPost,
        isNull,
      );
    });
  });

  group('the share sheet', () {
    Future<void> open(
      WidgetTester tester, {
      required bool canRepost,
      required bool canCopyLink,
    }) async {
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showShareSheet(
                context,
                canRepost: canRepost,
                canCopyLink: canCopyLink,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers repost, send and the link', (tester) async {
      await open(tester, canRepost: true, canCopyLink: true);

      expect(find.text('Repost'), findsOneWidget);
      expect(find.text('Send in message'), findsOneWidget);
      expect(find.text('Copy link'), findsOneWidget);
    });

    testWidgets(
        'a repost cannot be reposted, and no link without a web '
        'address', (tester) async {
      await open(tester, canRepost: false, canCopyLink: false);

      expect(find.text('Repost'), findsNothing);
      expect(find.text('Copy link'), findsNothing);
      expect(find.text('Send in message'), findsOneWidget);
    });
  });

  group('send in a message', () {
    Future<void> open(WidgetTester tester) async {
      when(() => api.get(ApiEndpoints.conversations)).thenAnswer(
        (_) async => {
          'data': [
            _chat('c1', 'Maria'),
            _chat('c2', 'Sky Hall inbox', inbox: true),
            _chat('c3', 'Pending Pat', status: 'pending'),
            _chat('c4', 'Jon'),
          ],
        },
      );
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSendPostSheet(context, _post),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('lists accepted people chats only, and filters by name', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Jon'), findsOneWidget);
      expect(find.text('Sky Hall inbox'), findsNothing);
      expect(find.text('Pending Pat'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'mar');
      await tester.pump();
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Jon'), findsNothing);
    });

    testWidgets('Send waits for someone, then sends the post to each', (
      tester,
    ) async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});
      await open(tester);

      expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Maria'));
      await tester.tap(find.text('Jon'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'look!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
      await tester.pumpAndSettle();

      for (final id in ['c1', 'c4']) {
        verify(
          () => api.post(
            ApiEndpoints.conversationMessages(id),
            {'content': 'look!', 'sharedPostId': 'p1'},
          ),
        ).called(1);
      }
    });
  });

  group('the repost sheet', () {
    testWidgets('can be sent with nothing written', (tester) async {
      String? result;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await showComposeSheet(
                context,
                title: 'Repost to your feed',
                action: 'Repost',
                allowEmpty: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Repost'));
      await tester.pumpAndSettle();

      expect(result, '');
    });
  });
}
