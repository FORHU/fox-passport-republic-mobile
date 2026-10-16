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
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _MockStorage extends Mock implements StorageService {}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'me@example.com', name: 'Me'),
      );
}

Conversation _conversation({bool muted = false}) => Conversation(
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
      isMuted: muted,
      status: 'accepted',
      isIncomingRequest: false,
      otherUserId: 'u2',
      otherUserVerified: true,
      otherUserRoles: const ['eventFoxer'],
    );

ChatMessage _message(String id, String sender, String text) => ChatMessage(
      id: id,
      senderId: sender,
      content: text,
      createdAt: DateTime.now(),
      attachmentUrls: const [],
      isSystem: false,
      isEdited: false,
    );

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(() => api.patch(any(), any())).thenAnswer((_) async => {});
    when(() => api.patch(ApiEndpoints.conversationRead('c1')))
        .thenAnswer((_) async => {});
    when(() => api.post(any(), any())).thenAnswer((_) async => {});
    when(() => api.delete(any())).thenAnswer((_) async => {});
  });

  Future<void> open(WidgetTester tester) async {
    final storage = _MockStorage();
    when(storage.readUserModel).thenReturn(null);
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          realtimeServiceProvider.overrideWithValue(null),
          authControllerProvider.overrideWith(_Auth.new),
          messagesRepositoryProvider.overrideWithValue(MessagesRepository(api)),
          conversationsProvider.overrideWith((ref) async => [_conversation()]),
          chatMessagesProvider.overrideWith(
            (ref, id) async => [
              _message('m1', 'u2', 'Sound check is at 5'),
              _message('m2', 'me', 'Perfect, thank you'),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MessagesChatPage(conversationId: 'c1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long press reacts to a message', (tester) async {
    await open(tester);

    await tester.longPress(find.text('Sound check is at 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🎉'));
    await tester.pumpAndSettle();

    verify(
      () => api.post(
        ApiEndpoints.conversationReaction('c1', 'm1'),
        {'emoji': '🎉'},
      ),
    ).called(1);
  });

  testWidgets('replying sends the id of the quoted message', (tester) async {
    await open(tester);

    await tester.longPress(find.text('Sound check is at 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(find.text('REPLYING TO'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'See you there');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(
      () => api.post(
        ApiEndpoints.conversationMessages('c1'),
        {'content': 'See you there', 'replyToId': 'm1'},
      ),
    ).called(1);
  });

  testWidgets('only your own messages can be edited or deleted', (
    tester,
  ) async {
    await open(tester);

    await tester.longPress(find.text('Sound check is at 5'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Perfect, thank you'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('editing patches the message and clears the composer', (
    tester,
  ) async {
    await open(tester);

    await tester.longPress(find.text('Perfect, thank you'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('EDITING MESSAGE'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Perfect, thanks');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(
      () => api.patch(
        ApiEndpoints.conversationMessage('c1', 'm2'),
        {'content': 'Perfect, thanks'},
      ),
    ).called(1);
  });

  testWidgets('a short chat sits at the bottom, by the composer', (
    tester,
  ) async {
    await open(tester);

    // Two short messages on an 1800 px screen: they hug the composer rather
    // than starting under the header.
    final newest = tester.getBottomLeft(find.text('Perfect, thank you')).dy;
    final composer = tester.getTopLeft(find.byType(TextField)).dy;

    expect(newest, greaterThan(1000));
    expect(composer - newest, lessThan(120));
  });

  testWidgets('the menu mutes the chat', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mute notifications'));
    await tester.pumpAndSettle();

    verify(
      () => api.patch(
        ApiEndpoints.conversationMute('c1'),
        {'muted': true},
      ),
    ).called(1);
  });
}
