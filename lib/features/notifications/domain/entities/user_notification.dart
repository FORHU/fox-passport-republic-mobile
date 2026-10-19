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
      link: _linkOf(json['metadata']),
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

  static String? _linkOf(Object? metadata) {
    final link = metadata is Map ? metadata['link'] : null;
    return link is String && link.isNotEmpty ? link : null;
  }

  @override
  List<Object?> get props =>
      [id, type, title, message, createdAt, isRead, link];
}
