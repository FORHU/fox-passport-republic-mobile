import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';

/// The posts loaded so far for one tab, and whether more can be loaded.
class FeedState extends Equatable {
  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Post> posts;
  final String? nextCursor;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  FeedState copyWith({
    List<Post>? posts,
    String? nextCursor,
    bool? loadingMore,
    bool? loadMoreFailed,
    bool clearCursor = false,
  }) =>
      FeedState(
        posts: posts ?? this.posts,
        nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );

  @override
  List<Object?> get props => [posts, nextCursor, loadingMore, loadMoreFailed];
}

/// The feed for one tab (`null` is all). Loads the first page, then more on
/// demand; a like is shown at once and put back if the server refuses it.
class FeedController extends AsyncNotifier<FeedState> {
  FeedController(this.tab);

  /// `community`, `marketplace`, `partners`, or null for every tab.
  final String? tab;

  @override
  Future<FeedState> build() async {
    final page = await ref.read(republicRepositoryProvider).feed(tab: tab);
    return FeedState(posts: page.posts, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await ref
          .read(republicRepositoryProvider)
          .feed(tab: tab, cursor: current.nextCursor);
      final known = {for (final p in current.posts) p.id};
      state = AsyncData(
        FeedState(
          posts: [
            ...current.posts,
            for (final p in page.posts)
              if (!known.contains(p.id)) p,
          ],
          nextCursor: page.nextCursor,
        ),
      );
    } on Object {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final page = await ref.read(republicRepositoryProvider).feed(tab: tab);
      return FeedState(posts: page.posts, nextCursor: page.nextCursor);
    });
  }

  /// A tap on Like: likes the post, or takes any reaction back.
  Future<bool> toggleLike(String postId) {
    final post = state.value?.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) return Future.value(false);
    return react(postId, post.isLikedByMe ? null : ReactionType.like);
  }

  /// Sets the reaction on [postId] (null takes it back), shown at once and
  /// put back if the server refuses. Returns false when it did.
  Future<bool> react(String postId, ReactionType? type) async {
    final current = state.value;
    if (current == null) return false;
    final post = current.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) return false;

    void put(Post p) {
      final latest = state.value;
      if (latest == null) return;
      final list = [...latest.posts];
      final i = list.indexWhere((x) => x.id == postId);
      if (i >= 0) list[i] = p;
      state = AsyncData(latest.copyWith(posts: list));
    }

    // Only the first reaction adds one; changing it keeps the count.
    final delta = (type != null ? 1 : 0) - (post.isLikedByMe ? 1 : 0);
    put(
      post.copyWith(
        myReaction: type,
        clearReaction: type == null,
        likesCount: (post.likesCount + delta).clamp(0, 1 << 30),
      ),
    );
    try {
      await ref.read(republicRepositoryProvider).setReaction(postId, type);
      return true;
    } on Object {
      put(post);
      return false;
    }
  }

  /// Bumps a post's comment count after the person comments.
  void commentAdded(String postId) {
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        posts: [
          for (final p in latest.posts)
            if (p.id == postId)
              p.copyWith(commentsCount: p.commentsCount + 1)
            else
              p,
        ],
      ),
    );
  }

  void _replace(String postId, Post Function(Post) change) {
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        posts: [
          for (final p in latest.posts)
            if (p.id == postId) change(p) else p,
        ],
      ),
    );
  }

  /// Takes a post out of the list: deleted, hidden, or unsaved on Saved.
  void removeLocally(String postId) {
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        posts: [
          for (final p in latest.posts)
            if (p.id != postId) p,
        ],
      ),
    );
  }

  /// Saves or unsaves. Returns false when the server refuses.
  Future<bool> toggleSave(String postId) async {
    try {
      final saved =
          await ref.read(republicRepositoryProvider).toggleSave(postId);
      if (tab == RepublicRepository.savedTab && !saved) {
        removeLocally(postId);
      } else {
        _replace(postId, (p) => p.copyWith(isSavedByMe: saved));
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> hide(String postId) async {
    await ref.read(republicRepositoryProvider).hide(postId);
    removeLocally(postId);
  }

  Future<void> delete(String postId) async {
    await ref.read(republicRepositoryProvider).delete(postId);
    removeLocally(postId);
  }

  Future<void> edit(String postId, String content) async {
    await ref.read(republicRepositoryProvider).edit(postId, content);
    _replace(
      postId,
      (p) => p.copyWith(content: content.trim(), edited: true),
    );
  }
}

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final feedControllerProvider = AsyncNotifierProvider.autoDispose
    .family<FeedController, FeedState, String?>(FeedController.new);
