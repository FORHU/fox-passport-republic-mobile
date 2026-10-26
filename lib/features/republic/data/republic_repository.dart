import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
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

  /// A text post in the community tab.
  Future<void> createPost(String content) async {
    await _api.post(ApiEndpoints.feed, {
      'type': 'citizen_experience',
      'tab': 'community',
      'content': content.trim(),
      'visibility': 'public',
    });
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
