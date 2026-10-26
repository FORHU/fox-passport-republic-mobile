import 'package:equatable/equatable.dart';

/// The kinds of post that can be written on the phone, as the API names them.
enum ComposeType {
  story('citizen_experience'),
  poll('poll'),
  venueSpotlight('venue_spotlight');

  const ComposeType(this.api);

  final String api;
}

/// Who can see a post, as the API names it.
enum PostVisibility {
  public('public'),
  followers('followers'),
  onlyMe('only_me');

  const PostVisibility(this.api);

  final String api;
}

/// A post being sent.
class NewPost extends Equatable {
  const NewPost({
    required this.type,
    required this.content,
    this.mediaUrls = const [],
    this.visibility = PostVisibility.public,
    this.venueId,
    this.pollOptions = const [],
  });

  final ComposeType type;
  final String content;
  final List<String> mediaUrls;
  final PostVisibility visibility;
  final String? venueId;
  final List<String> pollOptions;

  Map<String, Object?> toJson() => {
        'type': type.api,
        'content': content.trim(),
        'mediaUrls': mediaUrls,
        'visibility': visibility.api,
        if (venueId != null) 'venueId': venueId,
        if (type == ComposeType.poll) 'pollOptions': pollOptions,
      };

  @override
  List<Object?> get props =>
      [type, content, mediaUrls, visibility, venueId, pollOptions];
}

/// Someone who can be @mentioned.
class MentionCandidate extends Equatable {
  const MentionCandidate({
    required this.id,
    required this.name,
    this.username,
    this.imageUrl,
  });

  static MentionCandidate? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (id == null) return null;
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final username = text(json['username']);
    return MentionCandidate(
      id: '$id',
      name: text(json['name']) ?? username ?? '',
      username: username,
      imageUrl: text(json['imgId']),
    );
  }

  final String id;
  final String name;
  final String? username;
  final String? imageUrl;

  /// What goes after the `@` when chosen.
  String get handle => username ?? name;

  @override
  List<Object?> get props => [id, name, username, imageUrl];
}

/// One of the person's venues, to spotlight in a post.
class VenueChoice extends Equatable {
  const VenueChoice({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Finds the `@word` the cursor is at the end of, or null. [text] is
/// everything before the cursor.
String? mentionQueryAt(String text) {
  final match = RegExp(r'(?:^|\s)@([A-Za-z0-9_]{0,32})$').firstMatch(text);
  return match?.group(1);
}
