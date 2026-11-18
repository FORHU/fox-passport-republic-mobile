import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/republic/data/feed_realtime.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';

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

class FeedModeNotifier extends Notifier<FeedMode> {
  @override
  FeedMode build() => FeedMode.forYou;

  // A method, like FeedSearchNotifier.set: picking an order is an action the
  // page calls, and a setter on a notifier reads as a field.
  // ignore: use_setters_to_change_properties
  void select(FeedMode mode) => state = mode;
}

/// How the main feed is ordered: For you (the default) or Recent. Changing it
/// reloads every feed tab (app#308).
final feedModeProvider =
    NotifierProvider<FeedModeNotifier, FeedMode>(FeedModeNotifier.new);

/// Posts this many or fewer are put on top by "New posts"; more reload.
const newPostsBatch = 20;

/// The posts loaded so far for one tab, and whether more can be loaded.
class FeedState extends Equatable {
  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.since,
    this.newCount = 0,
  });

  final List<Post> posts;
  final String? nextCursor;
  final bool loadingMore;
  final bool loadMoreFailed;

  /// Posts after this moment are not in the list: For you's session start, or
  /// Recent's newest post. Null where there is no "New posts" pill.
  final DateTime? since;

  /// How many posts the viewer may see arrived after [since].
  final int newCount;

  bool get hasMore => nextCursor != null;

  FeedState copyWith({
    List<Post>? posts,
    String? nextCursor,
    bool? loadingMore,
    bool? loadMoreFailed,
    bool clearCursor = false,
    DateTime? since,
    int? newCount,
  }) =>
      FeedState(
        posts: posts ?? this.posts,
        nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        since: since ?? this.since,
        newCount: newCount ?? this.newCount,
      );

  @override
  List<Object?> get props =>
      [posts, nextCursor, loadingMore, loadMoreFailed, since, newCount];
}

/// The feed for one tab (`null` is all). Loads the first page, then more on
/// demand; a like is shown at once and put back if the server refuses it.
class FeedController extends AsyncNotifier<FeedState> {
  FeedController(this.tab);

  /// `community`, `marketplace`, `partners`, or null for every tab.
  final String? tab;

  /// The saved list and one person's posts are not searched like the feed
  /// is.
  bool get _plain =>
      tab == RepublicRepository.savedTab ||
      (tab?.startsWith(RepublicRepository.authorPrefix) ?? false);

  Future<FeedPage> _page({String? cursor}) {
    final search = _plain ? null : ref.read(feedSearchProvider);
    return ref.read(republicRepositoryProvider).feed(
          tab: tab,
          cursor: cursor,
          search: search,
          mode: _plain ? null : ref.read(feedModeProvider),
        );
  }

  /// A first page: for For you, a new session (a new mix).
  Future<FeedState> _firstPage() async {
    final page = await _page();
    final DateTime? since;
    if (_plain) {
      since = null;
    } else if (ref.read(feedModeProvider) == FeedMode.forYou) {
      since = page.anchor;
    } else {
      since = page.posts.firstOrNull?.createdAt;
    }
    return FeedState(
      posts: page.posts,
      nextCursor: page.nextCursor,
      since: since,
    );
  }

  Timer? _coalesce;

  @override
  Future<FeedState> build() async {
    // Watched, so a search or a new order reloads the list.
    if (!_plain) {
      ref
        ..watch(feedSearchProvider)
        ..watch(feedModeProvider);
    }
    // Someone commented, or deleted one, on a post this list may show.
    ref.listen(postCommentsCountProvider, (_, next) {
      final change = next.value;
      if (change == null) return;
      _replace(
        change.postId,
        (p) => p.copyWith(commentsCount: change.commentsCount),
      );
    });
    if (!_plain) _watchForNewPosts();
    return _firstPage();
  }

  /// Keeps [FeedState.newCount] current: on each `feed:new` for this tab (a
  /// burst becomes one request), or every minute when no socket will say.
  void _watchForNewPosts() {
    ref.listen(feedNewProvider, (_, next) {
      final event = next.value;
      if (event == null) return;
      if (tab != null && event.tab != tab) return;
      _coalesce?.cancel();
      _coalesce = Timer(const Duration(milliseconds: 1500), _checkNew);
    });
    // Listened, not watched: signing in or out restarts the timer without
    // reloading the list, and a provider that can't tell (no session store,
    // as in tests) just means no polling rather than a broken feed.
    ref.listen<Duration?>(
      feedNewPollIntervalProvider,
      (_, interval) => _poll(interval),
      onError: (_, __) => _poll(null),
      fireImmediately: true,
    );
    ref.onDispose(() {
      _pollTimer?.cancel();
      _coalesce?.cancel();
    });
  }

  Timer? _pollTimer;

  void _poll(Duration? interval) {
    _pollTimer?.cancel();
    _pollTimer = interval == null
        ? null
        : Timer.periodic(interval, (_) {
            final life = WidgetsBinding.instance.lifecycleState;
            if (life != null && life != AppLifecycleState.resumed) return;
            unawaited(_checkNew());
          });
  }

  Future<void> _checkNew() async {
    final since = state.value?.since;
    // The count can't be filtered by words, so searches get no pill.
    if (since == null || ref.read(feedSearchProvider).isNotEmpty) return;
    try {
      final count = await ref
          .read(republicRepositoryProvider)
          .newPostsCount(since: since, tab: tab);
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest == null || latest.since != since) return;
      state = AsyncData(latest.copyWith(newCount: count));
    } on Object {
      // Best-effort: the next event or poll tries again.
    }
  }

  /// "New posts": puts the posts that arrived after [FeedState.since] on top,
  /// leaving the rest of the list (and For you's session) as it was.
  Future<void> showNewPosts() async {
    final current = state.value;
    final since = current?.since;
    if (current == null || since == null) return;
    if (current.newCount > newPostsBatch) return refresh();
    try {
      final page = await ref.read(republicRepositoryProvider).feed(
            tab: tab,
            mode: FeedMode.recent,
            limit: newPostsBatch,
          );
      if (!ref.mounted) return;
      final latest = state.value;
      if (latest == null) return;
      final known = {for (final p in latest.posts) p.id};
      final newer = [
        for (final p in page.posts)
          if (p.createdAt != null &&
              p.createdAt!.isAfter(since) &&
              !known.contains(p.id))
            p,
      ];
      var newest = since;
      for (final p in newer) {
        if (p.createdAt!.isAfter(newest)) newest = p.createdAt!;
      }
      state = AsyncData(
        latest.copyWith(
          posts: [...newer, ...latest.posts],
          since: newest,
          newCount: 0,
        ),
      );
    } on Object {
      // The pill stays; tapping it again tries again.
    }
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

  /// Pull to refresh: the first page again, so For you starts a new session
  /// and shows a new mix.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_firstPage);
  }

  /// Puts a post first in the list, for one you have just written: For you
  /// ranks it among the rest, so it would otherwise be a screen or two down.
  void addFirst(Post post) {
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        posts: [post, ...latest.posts.where((p) => p.id != post.id)],
      ),
    );
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
        reactionCounts: ReactionCount.change(
          post.reactionCounts,
          from: post.myReaction,
          to: type,
        ),
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
  /// have moved while the socket was not there to say so.
  Future<void> reload(String postId) async {
    try {
      final fresh = await ref.read(republicRepositoryProvider).post(postId);
      if (fresh != null) _replace(postId, (_) => fresh);
    } on Object {
      // The old count stays; a pull to refresh fixes it.
    }
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
