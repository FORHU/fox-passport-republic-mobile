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
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_chat_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/shared/widgets/media_viewer.dart';
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

/// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Hands back three photos at once, and records how many it was asked for.
class _ManyPicker implements PhotoPicker, MultiPhotoPicker {
  int? askedFor;

  @override
  Future<PickedPhoto?> pick() async => null;

  @override
  Future<List<PickedPhoto>> pickMany({required int limit}) async {
    askedFor = limit;
    return [
      for (final name in ['a.png', 'b.png', 'c.png'])
        PickedPhoto(bytes: _png, name: name),
    ];
  }
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

ChatMessage _photoMessage(List<String> urls) => ChatMessage(
      id: 'm1',
      senderId: 'u2',
      content: '',
      createdAt: DateTime.now(),
      attachmentUrls: urls,
      isSystem: false,
      isEdited: false,
    );

void main() {
  late _MockApi api;
  late _ManyPicker picker;

  setUp(() {
    api = _MockApi();
    picker = _ManyPicker();
    when(() => api.patch(any(), any())).thenAnswer((_) async => {});
    when(() => api.patch(ApiEndpoints.conversationRead('c1')))
        .thenAnswer((_) async => {});
    var uploaded = 0;
    when(
      () => api.post(ApiEndpoints.uploadFile, any(that: isA<FormData>())),
    ).thenAnswer((_) async {
      uploaded++;
      return {
        'file': {'url': 'https://cdn.example.com/$uploaded.png'},
      };
    });
    when(
      () => api.post(ApiEndpoints.conversationMessages('c1'), any()),
    ).thenAnswer((_) async => {});
  });

  Future<void> open(
    WidgetTester tester, {
    List<ChatMessage> messages = const [],
  }) async {
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
          authControllerProvider.overrideWith(_Auth.new),
          realtimeServiceProvider.overrideWithValue(null),
          photoPickerProvider.overrideWithValue(picker),
          messagesRepositoryProvider.overrideWithValue(MessagesRepository(api)),
          conversationsProvider.overrideWith((ref) async => [_conversation()]),
          chatMessagesProvider.overrideWith((ref, id) async => messages),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MessagesChatPage(conversationId: 'c1'),
        ),
      ),
    );
    // A photo that is still loading pulses forever, so it never settles.
    if (messages.isEmpty) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  testWidgets(
      'several photos are chosen, one is taken out, the rest are sent '
      'in one message', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    expect(picker.askedFor, 10);
    expect(find.text('a.png'), findsOneWidget);
    expect(find.text('b.png'), findsOneWidget);
    expect(find.text('c.png'), findsOneWidget);

    // Take b.png out: the second thumbnail's close button.
    await tester.tap(find.byIcon(Icons.close_rounded).at(1));
    await tester.pumpAndSettle();
    expect(find.text('b.png'), findsNothing);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(
      () => api.post(
        ApiEndpoints.conversationMessages('c1'),
        {
          'content': '',
          'attachmentUrls': [
            'https://cdn.example.com/1.png',
            'https://cdn.example.com/2.png',
          ],
        },
      ),
    ).called(1);
    expect(find.text('a.png'), findsNothing);
  });

  testWidgets('a sent photo opens full screen when tapped', (tester) async {
    await open(
      tester,
      messages: [
        _photoMessage(const [
          'https://cdn.example.com/1.png',
          'https://cdn.example.com/2.png',
        ]),
      ],
    );

    expect(find.byType(MediaViewer), findsNothing);
    await tester.tap(
      find
          .descendant(
            of: find.byType(Wrap),
            matching: find.byType(GestureDetector),
          )
          .at(1),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final viewer = tester.widget<MediaViewer>(find.byType(MediaViewer));
    expect(viewer.urls, hasLength(2));
    // The second tile was tapped, so the viewer starts on the second photo.
    expect(viewer.initialIndex, 1);
  });
}
