import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';

/// How the feed is ordered.
enum FeedSort { recent, top }

class FeedSortNotifier extends Notifier<FeedSort> {
  @override
  FeedSort build() => FeedSort.recent;

  // A method, not a setter: Notifier state is changed through calls.
  // ignore: use_setters_to_change_properties
  void choose(FeedSort sort) => state = sort;
}

/// The order every feed tab is read in. Changing it reloads them.
final feedSortProvider =
    NotifierProvider<FeedSortNotifier, FeedSort>(FeedSortNotifier.new);

class FeedSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  // Trims the words as they are set, so it is a method, not a setter.
  // ignore: use_setters_to_change_properties
  void set(String term) => state = term.trim();
}

/// The words the feed is filtered by; empty for none. Changing it reloads
/// every feed tab.
final feedSearchProvider =
    NotifierProvider<FeedSearchNotifier, String>(FeedSearchNotifier.new);

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

  /// The saved list is not sorted or searched like the feed is.
  bool get _plain => tab == RepublicRepository.savedTab;

  Future<FeedPage> _page({String? cursor}) {
    final top = !_plain && ref.read(feedSortProvider) == FeedSort.top;
    final search = _plain ? null : ref.read(feedSearchProvider);
    return ref.read(republicRepositoryProvider).feed(
          tab: tab,
          cursor: cursor,
          top: top,
          search: search,
        );
  }

  @override
  Future<FeedState> build() async {
    // Watched, so choosing a sort or a search reloads the list.
    if (!_plain) {
      ref
        ..watch(feedSortProvider)
        ..watch(feedSearchProvider);
    }
    final page = await _page();
    return FeedState(posts: page.posts, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await _page(cursor: current.nextCursor);
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
      final page = await _page();
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

  /// Takes the server's version of one post, for when its comment count may
  /// have moved in ways the phone cannot work out (comments deleted).
  Future<void> reload(String postId) async {
    try {
      final fresh = await ref.read(republicRepositoryProvider).post(postId);
      if (fresh != null) _replace(postId, (_) => fresh);
    } on Object {
      // The old count stays; a pull to refresh fixes it.
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

  /// Votes in a poll and shows the poll as the server now has it. Returns
  /// false when the vote did not go through.
  Future<bool> vote(String postId, String optionId) async {
    try {
      final poll =
          await ref.read(republicRepositoryProvider).vote(postId, optionId);
      if (poll == null) return false;
      _replace(postId, (p) => p.copyWith(poll: poll));
      return true;
    } on Object {
      return false;
    }
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
