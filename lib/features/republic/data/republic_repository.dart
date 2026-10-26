import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/media_picker.dart';
import 'package:flutter_template/features/republic/domain/new_post.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';

/// Reads and writes the Republic feed: posts, likes and comments.
class RepublicRepository {
  RepublicRepository(this._api);

  final ApiService _api;

  static const pageSize = 10;

  /// Not a tab of the feed: the posts this person saved. Passed as [feed]'s
  /// tab so one controller serves both.
  static const savedTab = 'saved';

  /// One page of posts. [tab] is `community`, `marketplace` or `partners`;
  /// null is all of them.
  Future<FeedPage> feed({String? tab, String? cursor}) async {
    final body = await _api.get(
      tab == savedTab ? ApiEndpoints.feedSaved : ApiEndpoints.feed,
      query: {
        'limit': pageSize,
        if (tab != null && tab != savedTab) 'tab': tab,
        if (cursor != null) 'cursor': cursor,
      },
    );
    if (body is! Map) return const FeedPage(posts: []);
    final data = body['data'];
    final next = body['nextCursor'];
    return FeedPage(
      posts: [
        for (final p in data as List? ?? const [])
          if (p is Map) Post.fromJson(p.cast<String, dynamic>()),
      ],
      nextCursor: next is String && next.isNotEmpty ? next : null,
    );
  }

  /// Reacts to a post, or takes the reaction back (`type: null`).
  Future<void> setReaction(String postId, ReactionType? type) async {
    await _api.post(ApiEndpoints.feedReaction(postId), {'type': type?.name});
  }

  /// How many people chose each reaction on a post.
  Future<List<ReactionCount>> reactions(String postId) async {
    final body = await _api.get(ApiEndpoints.feedReactions(postId));
    return ReactionCount.parseList(body is Map ? body['data'] : null);
  }

  Future<List<PostComment>> comments(String postId) async {
    final body = await _api.get(ApiEndpoints.feedComments(postId));
    final data = body is Map ? body['data'] : null;
    return [
      for (final c in data as List? ?? const [])
        if (c is Map) PostComment.fromJson(c.cast<String, dynamic>()),
    ];
  }

  Future<void> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    await _api.post(ApiEndpoints.feedComments(postId), {
      'content': content.trim(),
      if (parentId != null) 'parentId': parentId,
    });
  }

  /// Likes a comment, or takes the like back. Returns what the server now
  /// has: whether it is liked and how many likes it has.
  Future<({bool liked, int count})> toggleCommentLike(
    String postId,
    String commentId,
  ) async {
    final body = await _api.post(
      ApiEndpoints.feedCommentLike(postId, commentId),
    );
    final data = body is Map ? body['data'] : null;
    return (
      liked: data is Map && data['liked'] == true,
      count: data is Map ? (data['likesCount'] as num?)?.toInt() ?? 0 : 0,
    );
  }

  Future<void> editComment(
    String postId,
    String commentId,
    String content,
  ) async {
    await _api.patch(
      ApiEndpoints.feedComment(postId, commentId),
      {'content': content.trim()},
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete(ApiEndpoints.feedComment(postId, commentId));
  }

  /// One post as the server has it now.
  Future<Post?> post(String postId) async {
    final body = await _api.get(ApiEndpoints.feedPost(postId));
    final data = body is Map ? body['data'] : null;
    return data is Map ? Post.fromJson(data.cast<String, dynamic>()) : null;
  }

  /// Sends a post. The API puts it on the right tab for its type.
  Future<void> createPost(NewPost post) async {
    await _api.post(ApiEndpoints.feed, post.toJson());
  }

  /// Uploads a photo and returns its public URL, to attach to a post.
  Future<String> uploadMedia(PickedMedia photo) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
    });
    final body = await _api.post(ApiEndpoints.uploadFile, form);
    final file = body is Map ? body['file'] : null;
    final url = (file is Map ? file['url'] : null) ??
        (body is Map ? body['url'] : null);
    if (url is! String) throw const FormatException('No url in the upload');
    return url;
  }

  /// People whose name or username starts with [query], for an @mention.
  Future<List<MentionCandidate>> mentionCandidates(String query) async {
    final body = await _api.get(
      ApiEndpoints.feedMentionSearch,
      query: {'q': query},
    );
    final data = body is Map ? body['data'] : null;
    return [
      for (final row in data as List? ?? const [])
        if (MentionCandidate.tryParse(row) case final c?) c,
    ];
  }

  /// The venues [userId] hosts, to spotlight in a post.
  Future<List<VenueChoice>> myVenues(String userId) async {
    final body = await _api.get(
      ApiEndpoints.venues,
      query: {'hostId': userId, 'limit': 100},
    );
    final rows = body is Map ? (body['venues'] ?? body['data']) as List? : null;
    return [
      for (final row in rows ?? const [])
        if (row is Map && row['id'] != null && row['name'] is String)
          VenueChoice(id: '${row['id']}', name: row['name'] as String),
    ];
  }

  /// Saves a post, or takes it back out. Returns whether it is now saved.
  Future<bool> toggleSave(String postId) async {
    final body = await _api.post(ApiEndpoints.feedSave(postId));
    final data = body is Map ? body['data'] : null;
    return data is Map && data['saved'] == true;
  }

  /// Stops showing a post that is someone else's, for this person only.
  Future<void> hide(String postId) async {
    await _api.post(ApiEndpoints.feedHide(postId));
  }

  Future<void> delete(String postId) async {
    await _api.delete(ApiEndpoints.feedPost(postId));
  }

  Future<void> edit(String postId, String content) async {
    await _api
        .patch(ApiEndpoints.feedPost(postId), {'content': content.trim()});
  }

  Future<void> report(String postId, String reason) async {
    await _api.post(ApiEndpoints.reports, {
      'targetType': 'post',
      'targetId': postId,
      'reason': reason,
    });
  }
}

final republicRepositoryProvider = Provider<RepublicRepository>(
  (ref) => RepublicRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final postCommentsProvider =
    FutureProvider.autoDispose.family<List<PostComment>, String>(
  (ref, postId) => ref.watch(republicRepositoryProvider).comments(postId),
);
