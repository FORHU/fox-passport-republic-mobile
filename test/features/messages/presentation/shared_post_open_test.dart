import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_chat_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _MockStorage extends Mock implements StorageService {}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'me@example.com', name: 'Me'),
      );
}

const _conversation = Conversation(
  id: 'c1',
  title: 'Rico Rival',
  contextLabel: null,
  lastMessage: null,
  lastMessageIsMine: false,
  lastMessageAt: null,
  unreadCount: 0,
  isGroup: false,
  isInbox: false,
  inboxType: null,
  isPinned: false,
  isMuted: false,
  status: 'accepted',
  isIncomingRequest: false,
  otherUserId: 'u2',
  otherUserVerified: true,
  otherUserRoles: ['eventFoxer'],
);

void main() {
  // mobile#482: the person a post was sent to can open it from the chat.
  testWidgets('tapping a shared post opens that post', (tester) async {
    final api = _MockApi();
    when(() => api.patch(any(), any())).thenAnswer((_) async => {});
    when(() => api.patch(any())).thenAnswer((_) async => {});
    final storage = _MockStorage();
    when(storage.readUserModel).thenReturn(null);
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const MessagesChatPage(conversationId: 'c1'),
        ),
        GoRoute(
          path: '/republic/post/:id',
          builder: (_, state) =>
              Scaffold(body: Text('post ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          realtimeServiceProvider.overrideWithValue(null),
          authControllerProvider.overrideWith(_Auth.new),
          messagesRepositoryProvider.overrideWithValue(MessagesRepository(api)),
          conversationsProvider.overrideWith((ref) async => [_conversation]),
          chatMessagesProvider.overrideWith(
            (ref, id) async => [
              ChatMessage(
                id: 'm1',
                senderId: 'u2',
                content: '',
                createdAt: DateTime.now(),
                attachmentUrls: const [],
                isSystem: false,
                isEdited: false,
                sharedPost: const SharedPost(
                  id: 'p9',
                  authorName: 'Ana Reyes',
                  content: 'Sunset set at the pier',
                ),
              ),
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunset set at the pier'));
    await tester.pumpAndSettle();

    expect(find.text('post p9'), findsOneWidget);
  });
}
