class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.contextLabel,
    required this.lastMessage,
    required this.lastMessageIsMine,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isGroup,
    required this.isInbox,
    required this.inboxType,
    required this.isPinned,
    required this.isMuted,
    required this.status,
    required this.isIncomingRequest,
    required this.otherUserId,
    required this.otherUserVerified,
    required this.otherUserRoles,
    this.otherUserOnline = false,
    this.avatarUrl,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final otherUser = _asMap(json['otherUser']);
    final inbox = _asMap(json['inbox']);
    final lastMessage = _asMap(json['lastMessage']);
    final isInbox = json['isInbox'] == true;
    final isGroup = json['isGroup'] == true;
    final rawRoles = otherUser == null ? null : otherUser['roleType'];
    final roles = rawRoles is List
        ? rawRoles.whereType<String>().toList(growable: false)
        : const <String>[];
    final title = isInbox
        ? inbox == null
            ? null
            : inbox['name']
        : isGroup
            ? json['name']
            : otherUser == null
                ? null
                : otherUser['name'];
    final createdAt = json['createdAt'];
    final lastMessageAt = json['lastMessageAt'];

    if (json['id'] is! String ||
        title is! String ||
        createdAt is! String ||
        (lastMessageAt != null && lastMessageAt is! String)) {
      throw const FormatException('Invalid conversation response');
    }

    return Conversation(
      id: json['id'] as String,
      title: title,
      contextLabel: json['contextLabel'] as String?,
      lastMessage: lastMessage?['content'] as String?,
      lastMessageIsMine: lastMessage?['isMine'] == true,
      lastMessageAt: DateTime.tryParse(lastMessageAt as String? ?? createdAt),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isGroup: isGroup,
      isInbox: isInbox,
      inboxType: inbox == null ? null : inbox['type'] as String?,
      isPinned: json['isPinned'] == true,
      isMuted: json['isMuted'] == true,
      status: json['status'] == 'pending' ? 'pending' : 'accepted',
      isIncomingRequest: json['isIncomingRequest'] == true,
      otherUserId: otherUser?['id'] as String?,
      otherUserVerified: otherUser?['identityVerifiedAt'] != null,
      otherUserRoles: roles,
      otherUserOnline: otherUser?['isOnline'] == true,
      avatarUrl: (otherUser?['imgId'] ?? json['imgId']) as String?,
    );
  }

  final String id;
  final String title;
  final String? contextLabel;
  final String? lastMessage;
  final bool lastMessageIsMine;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isGroup;
  final bool isInbox;
  final String? inboxType;
  final bool isPinned;
  final bool isMuted;
  final String status;
  final bool isIncomingRequest;
  final String? otherUserId;
  final bool otherUserVerified;
  final List<String> otherUserRoles;
  final bool otherUserOnline;

  /// The other person's photo, or the group's.
  final String? avatarUrl;

  bool get hasPendingRequest => status == 'pending';
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Invalid conversation response');
}
