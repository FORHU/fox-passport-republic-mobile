import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';

String? _text(Object? v) =>
    v is String && v.trim().isNotEmpty ? v.trim() : null;

/// Who wrote a post or a comment.
class PostAuthor extends Equatable {
  const PostAuthor({required this.id, required this.name, this.imageUrl});

  factory PostAuthor.fromJson(Object? json) {
    final m =
        json is Map ? json.cast<String, dynamic>() : const <String, dynamic>{};
    return PostAuthor(
      id: '${m['id'] ?? ''}',
      name: _text(m['name']) ?? _text(m['username']) ?? '',
      imageUrl: _text(m['imgId']),
    );
  }

  final String id;
  final String name;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, imageUrl];
}

/// One post in the Republic feed.
class Post extends Equatable {
  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.tab = 'community',
    this.mediaUrls = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.myReaction,
    this.edited = false,
    this.isSavedByMe = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: '${json['id']}',
        author: PostAuthor.fromJson(json['author']),
        content: (json['content'] ?? '').toString().trim(),
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
        tab: _text(json['tab']) ?? 'community',
        mediaUrls: [
          for (final u in json['mediaUrls'] as List? ?? const [])
            if (_text(u) != null) _text(u)!,
        ],
        likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
        commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
        // Older rows only say that it was liked.
        myReaction: ReactionType.tryParse(json['myReaction']) ??
            (json['isLikedByMe'] == true ? ReactionType.like : null),
        edited: json['editedAt'] != null,
        isSavedByMe: json['isSavedByMe'] == true,
      );

  final String id;
  final PostAuthor author;
  final String content;
  final DateTime? createdAt;
  final String tab;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final ReactionType? myReaction;
  bool get isLikedByMe => myReaction != null;
  final bool edited;
  final bool isSavedByMe;

  Post copyWith({
    String? content,
    int? likesCount,
    int? commentsCount,
    ReactionType? myReaction,
    bool clearReaction = false,
    bool? isSavedByMe,
    bool? edited,
  }) =>
      Post(
        id: id,
        author: author,
        content: content ?? this.content,
        createdAt: createdAt,
        tab: tab,
        mediaUrls: mediaUrls,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        myReaction: clearReaction ? null : myReaction ?? this.myReaction,
        edited: edited ?? this.edited,
        isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      );

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        createdAt,
        tab,
        mediaUrls,
        likesCount,
        commentsCount,
        myReaction,
        edited,
        isSavedByMe,
      ];
}

/// A comment, with the replies under it (one level).
class PostComment extends Equatable {
  const PostComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.replies = const [],
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.edited = false,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: '${json['id']}',
        author: PostAuthor.fromJson(json['author']),
        content: (json['content'] ?? '').toString().trim(),
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
        replies: [
          for (final r in json['replies'] as List? ?? const [])
            if (r is Map) PostComment.fromJson(r.cast<String, dynamic>()),
        ],
        likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
        isLikedByMe: json['isLikedByMe'] == true,
        edited:
            json['updatedAt'] != null && json['updatedAt'] != json['createdAt'],
      );

  final String id;
  final PostAuthor author;
  final String content;
  final DateTime? createdAt;
  final List<PostComment> replies;
  final int likesCount;
  final bool isLikedByMe;
  final bool edited;

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        createdAt,
        replies,
        likesCount,
        isLikedByMe,
        edited,
      ];
}

/// One page of the feed and where the next one starts (null at the end).
class FeedPage extends Equatable {
  const FeedPage({required this.posts, this.nextCursor});

  final List<Post> posts;
  final String? nextCursor;

  @override
  List<Object?> get props => [posts, nextCursor];
}
