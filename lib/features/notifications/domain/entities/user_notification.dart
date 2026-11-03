import 'package:equatable/equatable.dart';

class UserNotification extends Equatable {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.link,
    this.eventTemplateId,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse('${json['createdAt']}');
    final id = json['id']?.toString();
    if (id == null || id.isEmpty || createdAt == null) {
      throw const FormatException('Notification is missing its id or date');
    }
    return UserNotification(
      id: id,
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: createdAt.toLocal(),
      isRead: json['isRead'] == true,
      link: _linkOf(json['metadata']) ??
          _postLinkOf(json['type'], json['metadata']),
      eventTemplateId: _waitlistTemplateOf(json['type'], json['metadata']),
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Where the web app sends this notification (`metadata.link`), e.g.
  /// `/booking/<id>` or `/messages?conversationId=<id>`; null when it has none.
  final String? link;

  /// The event a "a spot opened up" notification is about
  /// (`metadata.templateId`); null for every other kind.
  final String? eventTemplateId;

  static String? _waitlistTemplateOf(Object? type, Object? metadata) {
    if (type != waitlistSpotType || metadata is! Map) return null;
    final id = metadata['templateId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  /// The `type` the API gives a waitlist notification.
  static const waitlistSpotType = 'waitlist_spot_available';

  /// A Republic reaction, comment or mention names its post, not a link:
  /// the post's own address, with its comments open for the ones about them.
  static String? _postLinkOf(Object? type, Object? metadata) {
    if (type is! String || !type.startsWith('feed:') || metadata is! Map) {
      return null;
    }
    final postId = metadata['postId'];
    if (postId is! String || postId.isEmpty) return null;
    final about = type == 'feed:comment' || metadata['commentId'] != null;
    return Uri(
      path: '/republic',
      queryParameters: {'postId': postId, if (about) 'comments': '1'},
    ).toString();
  }

  static String? _linkOf(Object? metadata) {
    final link = metadata is Map ? metadata['link'] : null;
    return link is String && link.isNotEmpty ? link : null;
  }

  @override
  List<Object?> get props =>
      [id, type, title, message, createdAt, isRead, link, eventTemplateId];
}
