import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late MessagesRepository repository;

  setUp(() {
    api = _MockApiService();
    repository = MessagesRepository(api);
  });

  test('parses conversation list response including unread/context data',
      () async {
    when(() => api.get(ApiEndpoints.conversations)).thenAnswer(
      (_) async => {
        'success': true,
        'data': [
          {
            'id': 'conversation-1',
            'isGroup': false,
            'isInbox': false,
            'otherUser': {
              'id': 'user-2',
              'name': 'Rico Rival',
              'roleType': ['eventFoxer'],
              'identityVerifiedAt': '2026-01-01T00:00:00.000Z',
              'isOnline': true,
            },
            'contextLabel': 'Sky Hall · Sat 17 Oct',
            'lastMessageAt': '2026-10-13T06:00:00.000Z',
            'createdAt': '2026-10-12T06:00:00.000Z',
            'unreadCount': 2,
            'status': 'accepted',
            'isIncomingRequest': false,
            'lastMessage': {'content': 'See you there', 'isMine': false},
            'isMuted': false,
            'isPinned': true,
          },
        ],
      },
    );

    final conversations = await repository.getConversations();

    expect(conversations, hasLength(1));
    expect(conversations.single.title, 'Rico Rival');
    expect(conversations.single.contextLabel, 'Sky Hall · Sat 17 Oct');
    expect(conversations.single.unreadCount, 2);
    expect(conversations.single.otherUserVerified, isTrue);
    expect(conversations.single.otherUserRoles, ['eventFoxer']);
    expect(conversations.single.otherUserOnline, isTrue);
    expect(conversations.single.isPinned, isTrue);
  });

  test('loads and sends messages using the conversation API routes', () async {
    when(() => api.get(ApiEndpoints.conversationMessages('conversation-1')))
        .thenAnswer(
      (_) async => {
        'success': true,
        'data': [
          {
            'id': 'message-1',
            'senderId': 'user-2',
            'content': 'Hello',
            'createdAt': '2026-10-13T06:00:00.000Z',
            'attachmentUrls': <String>[],
            'replyTo': {'content': 'Can we add a photographer?'},
            'reactions': [
              {'emoji': '👍', 'count': 1},
            ],
            'readAt': '2026-10-13T06:01:00.000Z',
          },
        ],
      },
    );
    when(
      () => api.post(
        ApiEndpoints.conversationMessages('conversation-1'),
        {'content': 'Hi back'},
      ),
    ).thenAnswer((_) async => {'success': true});

    final messages = await repository.getMessages('conversation-1');
    await repository.sendMessage('conversation-1', 'Hi back');

    expect(messages.single.content, 'Hello');
    expect(messages.single.replyToContent, 'Can we add a photographer?');
    expect(messages.single.reactions.single.emoji, '👍');
    expect(messages.single.reactions.single.count, 1);
    expect(messages.single.isRead, isTrue);
    verify(
      () => api.post(
        ApiEndpoints.conversationMessages('conversation-1'),
        {'content': 'Hi back'},
      ),
    ).called(1);
  });

  test('starts a chat with a user and returns its id', () async {
    when(
      () => api.post(ApiEndpoints.conversations, {'otherUserId': 'u2'}),
    ).thenAnswer(
      (_) async => {
        'success': true,
        'data': {'id': 'c9'},
      },
    );

    expect(await repository.startWithUser('u2'), 'c9');
  });

  test('opens a venue inbox chat from the venue id', () async {
    when(
      () => api.post(ApiEndpoints.conversationsInbox, {'venueId': 'v1'}),
    ).thenAnswer(
      (_) async => {
        'success': true,
        'data': {'id': 'c5'},
      },
    );

    expect(await repository.startVenueInbox('v1'), 'c5');
  });

  test('a start response without an id is an error', () async {
    when(() => api.post(ApiEndpoints.conversationsInbox, any())).thenAnswer(
      (_) async => {'success': true, 'data': <String, dynamic>{}},
    );

    expect(
      repository.startVenueInbox('v1'),
      throwsA(isA<FormatException>()),
    );
  });
}
