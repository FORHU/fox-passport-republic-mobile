class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.attachmentUrls,
    required this.isSystem,
    required this.isEdited,
    this.replyToContent,
    this.reactions = const [],
    this.isRead = false,
    this.sharedPost,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final senderId = json['senderId'];
    final content = json['content'];
    final createdAt = json['createdAt'];
    if (id is! String ||
        senderId is! String ||
        content is! String ||
        createdAt is! String) {
      throw const FormatException('Invalid message response');
    }
    final rawAttachments = json['attachmentUrls'];
    final attachments = rawAttachments is List
        ? rawAttachments.whereType<String>().toList(growable: false)
        : const <String>[];
    final rawReply = json['replyTo'];
    final replyTo = rawReply is Map
        ? Map<String, dynamic>.from(rawReply)
        : const <String, dynamic>{};
    final rawReactions = json['reactions'];
    if (rawReactions != null && rawReactions is! List) {
      throw const FormatException('Invalid message reactions');
    }
    final reactions = (rawReactions as List? ?? const [])
        .map(MessageReaction.fromJson)
        .toList(growable: false);
    return ChatMessage(
      id: id,
      senderId: senderId,
      content: content,
      createdAt: DateTime.parse(createdAt),
      attachmentUrls: attachments,
      isSystem: json['type'] == 'system',
      isEdited: json['editedAt'] != null,
      replyToContent:
          json['replyToContent'] as String? ?? replyTo['content'] as String?,
      reactions: reactions,
      isRead: json['readAt'] != null,
      sharedPost: SharedPost.tryParse(json['sharedPost']),
    );
  }

  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final List<String> attachmentUrls;
  final bool isSystem;
  final bool isEdited;
  final String? replyToContent;
  final List<MessageReaction> reactions;
  final bool isRead;

  /// A Republic post that was sent in this message.
  final SharedPost? sharedPost;
}

/// Just enough of a Republic post to show it as a card in a chat.
class SharedPost {
  const SharedPost({
    required this.id,
    required this.authorName,
    required this.content,
    this.imageUrl,
  });

  static SharedPost? tryParse(Object? value) {
    if (value is! Map || value['id'] == null) return null;
    final author = value['author'];
    final media = value['mediaUrls'];
    final first = media is List && media.isNotEmpty ? media.first : null;
    return SharedPost(
      id: '${value['id']}',
      authorName: author is Map ? '${author['name'] ?? ''}'.trim() : '',
      content: '${value['content'] ?? ''}'.trim(),
      imageUrl: first is String && first.isNotEmpty ? first : null,
    );
  }

  final String id;
  final String authorName;
  final String content;
  final String? imageUrl;
}

class MessageReaction {
  const MessageReaction({required this.emoji, required this.count});

  factory MessageReaction.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid message reaction');
    }
    final reaction = Map<String, dynamic>.from(value);
    final emoji = reaction['emoji'];
    final count = reaction['count'];
    if (emoji is! String || count is! num) {
      throw const FormatException('Invalid message reaction');
    }
    return MessageReaction(emoji: emoji, count: count.toInt());
  }

  final String emoji;
  final int count;
}
