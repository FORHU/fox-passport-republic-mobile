import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/feed_video_focus.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/videos_page.dart';
import 'package:flutter_template/features/republic/presentation/widgets/feed_skeleton.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_actions.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/features/republic/presentation/widgets/videos_shelf.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The Republic: what the community is posting. Everyone can read; liking,
/// commenting and posting need an account.
class RepublicPage extends ConsumerStatefulWidget {
  const RepublicPage({super.key});

  @override
  ConsumerState<RepublicPage> createState() => _RepublicPageState();
}

class _RepublicPageState extends ConsumerState<RepublicPage> {
  // Tab ids as the API names them; null is everything.
  static const _tabs = <String?>[null, 'community', 'marketplace', 'partners'];

  // The menu's id for "All", which has no tab id of its own.
  static const _allSections = 'all';

  String? _tab;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  bool _searching = false;

  // The tab's two views, side by side: Posts (0) and Videos (1).
  final _views = PageController();

  /// The video the Videos view opens at, when it was opened from a post or a
  /// tile; null opens at the first one.
  String? _videoPostId;

  // Changed to start the Videos view over, such as after posting a video.
  int _videosKey = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _views.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      unawaited(ref.read(feedControllerProvider(_tab).notifier).loadMore());
    }
  }

  bool _signedIn() {
    if (ref.read(authControllerProvider).user != null) return true;
    showTopToast(context, context.l10n.signInToContinue);
    return false;
  }

  PostActions get _actions => PostActions(context, ref, _tab);

  void _applySearch(String term) {
    ref.read(feedSearchProvider.notifier).set(term);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _clearSearch() {
    _search.clear();
    _applySearch('');
  }

  /// A tapped `#tag` searches for it.
  void _searchFor(String tag) {
    _search.text = tag;
    setState(() => _searching = true);
    _applySearch(tag);
  }

  Future<void> _compose({bool video = false}) async {
    if (!_signedIn()) return;
    final id = await context.push<String>(
      video ? RouteNames.republicComposeVideo : RouteNames.republicCompose,
    );
    if (id == null || !mounted) return;
    // The Videos view starts over, so it opens on the newest video.
    if (video) setState(() => _videosKey++);
    showTopToast(context, context.l10n.republicPosted);
    final repo = ref.read(republicRepositoryProvider);
    Post? post;
    try {
      post = id.isEmpty ? null : await repo.post(id);
    } on Object {
      post = null;
    }
    if (!mounted) return;
    if (post == null) {
      // Not read back: a fresh list will have it, wherever it sorts.
      await ref.read(feedControllerProvider(_tab).notifier).refresh();
      return;
    }
    // The post may belong to a tab other than the open one: open its tab.
    if (_tab != null && _tab != post.tab) {
      setState(() => _tab = post!.tab);
      // Let the page start watching the new tab's list first: read before
      // that, it would be built, dropped and built again.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    await ref.read(feedControllerProvider(_tab).future);
    if (!mounted) return;
    ref.read(feedControllerProvider(_tab).notifier).addFirst(post);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  /// Shows the Videos view, at one post if given.
  void _openVideos({String? postId}) {
    setState(() => _videoPostId = postId);
    unawaited(_showView(1));
  }

  Future<void> _showView(int view) => _views.animateToPage(
        view,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  void _onViewChanged(int view) {
    // The feed's videos stop while the Videos view is showing.
    ref.read(feedVideoFocusProvider).suspend(view != 0);
    // Back on Posts, the next swipe to Videos starts at the first one.
    if (view == 0 && _videoPostId != null) {
      setState(() => _videoPostId = null);
    }
  }

  String _tabLabel(String? tab) {
    final l10n = context.l10n;
    return switch (tab) {
      'community' => l10n.republicTabCommunity,
      'marketplace' => l10n.republicTabMarketplace,
      'partners' => l10n.republicTabPartners,
      _ => l10n.republicTabAll,
    };
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedControllerProvider(_tab));
    final term = ref.watch(feedSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          PageView(
            controller: _views,
            onPageChanged: _onViewChanged,
            children: [
              _KeepAlive(
                child: SafeArea(
                  bottom: false,
                  child: _posts(context, feed, term),
                ),
              ),
              // Dropped when swiped away, so it stops playing.
              VideosPage(
                key: ValueKey(_videosKey),
                tab: _tab,
                initialPostId: _videoPostId,
                onPost: () => unawaited(_compose(video: true)),
              ),
            ],
          ),
          // Over both views, so it stays put as they slide. It keeps clear of
          // the header buttons on each side (a back arrow, or filter and
          // search): 100 is room for two buttons, and it shrinks to fit
          // rather than run under them on a narrow phone.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 100, top: 8, right: 100),
              child: Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  child: _ViewSwitch(controller: _views, onSelect: _showView),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The Posts view: the header, the sections and the feed.
  Widget _posts(BuildContext context, AsyncValue<FeedState> feed, String term) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Navigator.canPop(context) ? 8 : 16,
            8,
            8,
            0,
          ),
          child: Row(
            children: [
              // A tab now; the arrow only shows if it was pushed.
              if (Navigator.canPop(context))
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              // Where the Posts | Reels switch floats.
              const Expanded(child: SizedBox(height: 48)),
              // The sections (All, Community, Marketplace, Partners): lit
              // while one is picked.
              PopupMenuButton<String>(
                tooltip: l10n.republicFilterSections,
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(40, 40)),
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.tune_rounded,
                  size: 26,
                  color: _tab != null ? AppColors.accent : null,
                ),
                onSelected: (id) =>
                    setState(() => _tab = id == _allSections ? null : id),
                itemBuilder: (context) => [
                  for (final t in _tabs)
                    CheckedPopupMenuItem<String>(
                      value: t ?? _allSections,
                      checked: t == _tab,
                      child: Text(_tabLabel(t)),
                    ),
                ],
              ),
              IconButton(
                tooltip: l10n.republicSearchHint,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 40, height: 40),
                onPressed: () {
                  if (_searching && _search.text.isNotEmpty) {
                    _clearSearch();
                  }
                  setState(() => _searching = !_searching);
                },
                // The same magnifier open or shut: it lights up while the
                // search field is showing.
                icon: Icon(
                  Icons.search_rounded,
                  size: 28,
                  color: _searching ? AppColors.accent : null,
                ),
              ),
            ],
          ),
        ),
        if (_searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _applySearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.republicSearchHint,
                suffixIcon: IconButton(
                  tooltip: l10n.republicClearSearch,
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        // Only while a section is picked: what the feed is narrowed to, and
        // a way back to everything.
        if (_tab != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_tabLabel(_tab)),
                onDeleted: () => setState(() => _tab = null),
              ),
            ),
          ),
        Expanded(
          child: feed.when(
            loading: () => const FeedSkeleton(),
            error: (_, __) => AppStateView(
              kind: AppStateKind.error,
              title: l10n.apiLoadFailed,
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(feedControllerProvider(_tab)),
            ),
            data: (state) => RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () =>
                  ref.read(feedControllerProvider(_tab).notifier).refresh(),
              // The composer is the first row, then the posts, each one
              // full width and split by a thick rule, like a feed.
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: state.posts.length + 2,
                separatorBuilder: (_, __) => const Divider(
                  height: 8,
                  thickness: 8,
                  color: AppColors.surface,
                ),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(
                      children: [
                        _ComposerRow(onTap: _compose),
                        // Videos right under the composer, but not while
                        // searching: the words are what is wanted then.
                        if (term.isEmpty)
                          VideosShelf(
                            posts: state.posts,
                            onOpen: (p) => _openVideos(postId: p.id),
                            onSeeAll: _openVideos,
                          ),
                      ],
                    );
                  }
                  if (i == state.posts.length + 1) {
                    return state.posts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Text(
                                  term.isEmpty
                                      ? l10n.republicEmpty
                                      : l10n.republicSearchEmpty(term),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (term.isNotEmpty)
                                  TextButton(
                                    onPressed: _clearSearch,
                                    child: Text(l10n.republicClearSearch),
                                  ),
                              ],
                            ),
                          )
                        : _Footer(
                            state: state,
                            onRetry: () => unawaited(
                              ref
                                  .read(
                                    feedControllerProvider(_tab).notifier,
                                  )
                                  .loadMore(),
                            ),
                          );
                  }
                  final post = state.posts[i - 1];
                  return PostCard(
                    post: post,
                    onLike: () => unawaited(_actions.like(post.id)),
                    onComments: () => unawaited(_actions.comments(post.id)),
                    onMore: () => unawaited(_actions.menu(post)),
                    onAuthor: () => unawaited(
                      context.push(RouteNames.citizen(post.author.id)),
                    ),
                    onReact: (r) => unawaited(_actions.react(post.id, r)),
                    onReactions: () => unawaited(_actions.reactions(post.id)),
                    myUserId: ref.read(authControllerProvider).user?.id,
                    onVote: (o) => unawaited(_actions.vote(post.id, o)),
                    onOpenListing: () => _actions.openListing(post),
                    onMessage: () => unawaited(_actions.messageAuthor(post)),
                    onShare: () => unawaited(_actions.share(post)),
                    onHashtag: _searchFor,
                    onOpenVideo: () => _openVideos(postId: post.id),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Posts | Reels, the two views of the tab, as a small pill. The lime marker
/// follows the swipe, so the pill shows where the pages are. A dark,
/// see-through body keeps it readable over a bright video and over the feed.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.controller, required this.onSelect});

  final PageController controller;
  final ValueChanged<int> onSelect;

  static const _segmentWidth = 64.0;
  static const _height = 36.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [l10n.republicViewPosts, l10n.republicVideos];
    return SizedBox(
      height: 48,
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // 0 on Posts, 1 on Videos, in between while swiping.
            final page =
                controller.hasClients && controller.position.haveDimensions
                    ? (controller.page ?? 0).clamp(0.0, 1.0)
                    : 0.0;
            return Container(
              // The segments, 4 of padding each side and 1 of border.
              width: _segmentWidth * labels.length + 10,
              height: _height + 10,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.canvas.withValues(alpha: 0.6),
                borderRadius: AppRadius.brPill,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: page * _segmentWidth,
                    width: _segmentWidth,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        SizedBox(
                          width: _segmentWidth,
                          child: Semantics(
                            button: true,
                            selected: (page - i).abs() < 0.5,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelect(i),
                              child: Center(
                                child: Text(
                                  labels[i],
                                  maxLines: 1,
                                  style: AppTypography.display(
                                    size: 14,
                                    // Dark on the lime marker, light off it.
                                    color: Color.lerp(
                                          AppColors.textPrimary,
                                          AppColors.canvas,
                                          (1 - (page - i).abs())
                                              .clamp(0.0, 1.0),
                                        ) ??
                                        AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Keeps the Posts view built while the Videos view is showing, so its scroll
/// position and search are still there on the way back.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// "What's on your mind?": your photo and a field that opens the composer.
class _ComposerRow extends ConsumerWidget {
  const _ComposerRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            AuthorAvatar(
              author: PostAuthor(
                id: user?.id ?? '',
                name: user?.name ?? '',
                imageUrl: user?.imageUrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.republicComposePrompt,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            ),
            const Icon(Icons.image_outlined, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final FeedState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.loadMoreFailed) {
      return TextButton(
        onPressed: onRetry,
        child: Text(context.l10n.retry),
      );
    }
    return const SizedBox(height: 8);
  }
}
