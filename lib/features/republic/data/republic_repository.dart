import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/media_picker.dart';
import 'package:flutter_template/features/republic/domain/new_post.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/post_extras.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';

/// Reads and writes the Republic feed: posts, likes and comments.
class RepublicRepository {
  RepublicRepository(this._api);

  final ApiService _api;

  static const pageSize = 10;

  /// Not a tab of the feed: the posts this person saved. Passed as [feed]'s
  /// tab so one controller serves both.
  static const savedTab = 'saved';

  /// A feed of one person's posts is a tab named `author:<id>`.
  static const authorPrefix = 'author:';
  static String authorTab(String authorId) => '$authorPrefix$authorId';

  /// Not a tab either: one post, read by its id. Passed as [feed]'s tab so a
  /// single post gets the same actions as a post in the list.
  static const _postPrefix = 'post:';
  static String postTab(String postId) => '$_postPrefix$postId';

  /// One page of posts. [tab] is `community`, `marketplace` or `partners`;
  /// null is all of them.
  ///
  /// [top] sorts by what is popular instead of newest; [search] keeps
  /// posts that mention the words (a `#tag` works too).
  Future<FeedPage> feed({
    String? tab,
    String? cursor,
    bool top = false,
    String? search,
  }) async {
    if (tab != null && tab.startsWith(_postPrefix)) {
      final one = await post(tab.substring(_postPrefix.length));
      return FeedPage(posts: [if (one != null) one]);
    }
    final author = tab != null && tab.startsWith(authorPrefix)
        ? tab.substring(authorPrefix.length)
        : null;
    final body = await _api.get(
      tab == savedTab ? ApiEndpoints.feedSaved : ApiEndpoints.feed,
      query: {
        'limit': pageSize,
        if (author != null) 'authorId': author,
        if (tab != null && tab != savedTab && author == null) 'tab': tab,
        if (cursor != null) 'cursor': cursor,
        if (top) 'mode': 'top',
        if (search != null && search.isNotEmpty) 'search': search,
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

  /// Sends a post and returns its id (null if the answer has none). The API
  /// puts it on the right tab for its type.
  Future<String?> createPost(NewPost post) async {
    final body = await _api.post(ApiEndpoints.feed, post.toJson());
    final data = body is Map ? body['data'] : null;
    final id = data is Map ? data['id'] : null;
    return id == null ? null : '$id';
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

  /// Publishes a post of your own that quotes [postId]; the caption may be
  /// empty.
  Future<void> repost(String postId, String caption) async {
    await _api
        .post(ApiEndpoints.feedRepost(postId), {'caption': caption.trim()});
  }

  /// Saves a post, or takes it back out. Returns whether it is now saved.
  Future<bool> toggleSave(String postId) async {
    final body = await _api.post(ApiEndpoints.feedSave(postId));
    final data = body is Map ? body['data'] : null;
    return data is Map && data['saved'] == true;
  }

  /// Votes for an option, or takes the vote back by choosing it again.
  /// Returns the poll as the server now has it.
  Future<PostPoll?> vote(String postId, String optionId) async {
    final body = await _api.post(
      ApiEndpoints.feedPollVote(postId),
      {'optionId': optionId},
    );
    return PostPoll.tryParse(body is Map ? body['data'] : null);
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
