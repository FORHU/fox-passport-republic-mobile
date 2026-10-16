import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_chat_page.dart';
import 'package:flutter_template/features/messages/presentation/widgets/new_chat_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _MockStorage extends Mock implements StorageService {}

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async => PickedPhoto(
        // A 1x1 transparent PNG.
        bytes: Uint8List.fromList(const [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]),
        name: 'night.png',
      );
}

class _Auth extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'me@example.com', name: 'Me'),
      );
}

Conversation _conversation() => const Conversation(
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
      otherUserVerified: false,
      otherUserRoles: [],
    );

void main() {
  testWidgets('a chosen photo is uploaded, then sent as an attachment', (
    tester,
  ) async {
    final api = _MockApi();
    final storage = _MockStorage();
    when(storage.readUserModel).thenReturn(null);
    when(() => api.patch(any(), any())).thenAnswer((_) async => {});
    when(() => api.patch(ApiEndpoints.conversationRead('c1')))
        .thenAnswer((_) async => {});
    when(
      () => api.post(ApiEndpoints.uploadFile, any(that: isA<FormData>())),
    ).thenAnswer(
      (_) async => {
        'file': {'url': 'https://cdn.example.com/night.png'},
      },
    );
    when(
      () => api.post(ApiEndpoints.conversationMessages('c1'), any()),
    ).thenAnswer((_) async => {});
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          authControllerProvider.overrideWith(_Auth.new),
          realtimeServiceProvider.overrideWithValue(null),
          photoPickerProvider.overrideWithValue(_FakePicker()),
          messagesRepositoryProvider.overrideWithValue(MessagesRepository(api)),
          conversationsProvider.overrideWith((ref) async => [_conversation()]),
          chatMessagesProvider.overrideWith((ref, id) async => const []),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MessagesChatPage(conversationId: 'c1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    expect(find.text('night.png'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(
      () => api.post(
        ApiEndpoints.conversationMessages('c1'),
        {
          'content': '',
          'attachmentUrls': ['https://cdn.example.com/night.png'],
        },
      ),
    ).called(1);
    expect(find.text('night.png'), findsNothing);
  });

  testWidgets('the new-message sheet lists Foxers and opens the chat', (
    tester,
  ) async {
    final api = _MockApi();
    when(() => api.post(ApiEndpoints.conversations, {'otherUserId': 'f1'}))
        .thenAnswer(
      (_) async => {
        'data': {'id': 'c42'},
      },
    );
    String? opened;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          messagesRepositoryProvider.overrideWithValue(MessagesRepository(api)),
          conversationsProvider.overrideWith((ref) async => const []),
          catalogProvider.overrideWith(
            (ref, q) async => const CatalogPage(
              items: [
                CatalogItem(
                  id: 'f1',
                  kind: CatalogKind.foxers,
                  title: 'Rico Rival',
                  roles: ['eventFoxer'],
                ),
              ],
              total: 1,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => opened = await showNewChatSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('New message'), findsOneWidget);
    expect(find.text('Rico Rival'), findsOneWidget);
    expect(find.text('Event Foxer'), findsOneWidget);

    await tester.tap(find.text('Rico Rival'));
    await tester.pumpAndSettle();

    expect(opened, 'c42');
  });
}
