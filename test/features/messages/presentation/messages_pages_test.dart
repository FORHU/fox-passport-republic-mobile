import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_chat_page.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A time of day today. Tests that expect the "TODAY" separator must not
/// depend on the calendar date they happen to run on.
DateTime _todayAt(int hour, [int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}

class _MockApiService extends Mock implements ApiService {}

class _MockStorageService extends Mock implements StorageService {}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'user-1', email: 'test@example.com', name: 'Test'),
      );
}

Conversation _conversation({
  String id = 'conversation-1',
  bool group = false,
  bool request = false,
}) =>
    Conversation(
      id: id,
      title: group ? 'Planning group' : 'Rico Rival',
      contextLabel: 'Sky Hall · Sat 17 Oct',
      lastMessage: 'Sound check is at 5, see you there',
      lastMessageIsMine: false,
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 2)),
      unreadCount: 2,
      isGroup: group,
      isInbox: false,
      inboxType: null,
      isPinned: false,
      isMuted: false,
      status: request ? 'pending' : 'accepted',
      isIncomingRequest: request,
      otherUserId: 'user-2',
      otherUserVerified: true,
      otherUserRoles: const ['eventFoxer'],
      otherUserOnline: true,
    );

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('shows API conversation context, preview, and unread count', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(null),
          conversationsProvider.overrideWith(
            (ref) async => [_conversation()],
          ),
        ],
        child: _app(const MessagesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Rico Rival'), findsOneWidget);
    expect(find.text('Sky Hall · Sat 17 Oct'), findsOneWidget);
    expect(find.text('Sound check is at 5, see you there'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters group conversations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(null),
          conversationsProvider.overrideWith(
            (ref) async => [_conversation(), _conversation(group: true)],
          ),
        ],
        child: _app(const MessagesPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();

    expect(find.text('Planning group'), findsOneWidget);
    expect(find.text('Rico Rival'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders chat messages and sends text through the API', (
    tester,
  ) async {
    final api = _MockApiService();
    final storage = _MockStorageService();
    when(storage.readUserModel).thenReturn(null);
    when(
      () => api.patch(ApiEndpoints.conversationRead('conversation-1')),
    ).thenAnswer((_) async => {'success': true});
    when(
      () => api.post(
        ApiEndpoints.conversationMessages('conversation-1'),
        {'content': 'Perfect, thanks'},
      ),
    ).thenAnswer((_) async => {'success': true});
    final messageRepository = MessagesRepository(api);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          realtimeServiceProvider.overrideWithValue(null),
          authControllerProvider.overrideWith(_TestAuthController.new),
          messagesRepositoryProvider.overrideWithValue(messageRepository),
          conversationsProvider.overrideWith((ref) async => [_conversation()]),
          chatMessagesProvider.overrideWith(
            (ref, id) async => [
              ChatMessage(
                id: 'message-1',
                senderId: 'user-2',
                content: 'Hi, I am coordinating your night at Sky Hall.',
                createdAt: _todayAt(14),
                attachmentUrls: const [],
                isSystem: false,
                isEdited: false,
                replyToContent: 'Can we add a photographer?',
                reactions: const [
                  MessageReaction(emoji: '👍', count: 1),
                ],
              ),
              ChatMessage(
                id: 'message-2',
                senderId: 'user-1',
                content: 'Perfect, thanks',
                createdAt: _todayAt(14, 2),
                attachmentUrls: const [],
                isSystem: false,
                isEdited: false,
                isRead: true,
              ),
            ],
          ),
        ],
        child: _app(
          MessagesChatPage(
            conversationId: 'conversation-1',
            conversation: _conversation(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Hi, I am coordinating your night at Sky Hall.'),
      findsOneWidget,
    );
    expect(find.text('Event Foxer · Online'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Can we add a photographer?'), findsOneWidget);
    expect(find.text('👍 1'), findsOneWidget);
    expect(find.text('Seen'), findsOneWidget);
    // Icon-only buttons say what they do.
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Attach a photo'), findsOneWidget);
    expect(find.byTooltip('Send message'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Perfect, thanks');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(
      () => api.post(
        ApiEndpoints.conversationMessages('conversation-1'),
        {'content': 'Perfect, thanks'},
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts an incoming request before showing the composer', (
    tester,
  ) async {
    final api = _MockApiService();
    final storage = _MockStorageService();
    when(storage.readUserModel).thenReturn(null);
    when(
      () => api.patch(ApiEndpoints.conversationRead('conversation-1')),
    ).thenAnswer((_) async => {'success': true});
    when(
      () => api.post(ApiEndpoints.conversationAccept('conversation-1')),
    ).thenAnswer((_) async => {'success': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          realtimeServiceProvider.overrideWithValue(null),
          messagesRepositoryProvider.overrideWithValue(MessagesRepository(api)),
          conversationsProvider.overrideWith(
            (ref) async => [
              _conversation(request: true),
            ],
          ),
          chatMessagesProvider.overrideWith((ref, id) async => const []),
        ],
        child: _app(
          MessagesChatPage(
            conversationId: 'conversation-1',
            conversation: _conversation(request: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accept'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    verify(
      () => api.post(ApiEndpoints.conversationAccept('conversation-1')),
    ).called(1);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
