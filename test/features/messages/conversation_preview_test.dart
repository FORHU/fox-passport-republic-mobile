import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

Conversation _with(Map<String, Object?> lastMessage) => Conversation.fromJson({
      'id': 'c1',
      'createdAt': '2026-11-26T08:00:00.000Z',
      'otherUser': {'id': 'u2', 'name': 'Ana'},
      'lastMessage': lastMessage,
    });

/// The inbox line, as the web's `messagePreviewText` (api#514, app#443).
void main() {
  test('shows the text when there is any', () {
    final c = _with({'content': ' look ', 'hasSharedPost': true});
    expect(c.preview, isA<LastMessageText>());
    expect((c.preview as LastMessageText).text, 'look');
  });

  test('a post sent without a caption reads as a post', () {
    expect(
      _with({'content': '', 'hasSharedPost': true}).preview,
      isA<LastMessagePost>(),
    );
  });

  test('files sent without a caption read as an attachment', () {
    expect(
      _with({'content': '  ', 'hasAttachments': true}).preview,
      isA<LastMessageAttachment>(),
    );
  });

  test('a post wins over files when both came without text', () {
    expect(
      _with({'content': '', 'hasSharedPost': true, 'hasAttachments': true})
          .preview,
      isA<LastMessagePost>(),
    );
  });

  test('nothing to show without the flags (older API)', () {
    expect(_with({'content': ''}).preview, isA<LastMessageNone>());
  });
}
