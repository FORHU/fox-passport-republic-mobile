import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_actions.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
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

  String? _tab;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
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

  Future<void> _compose() async {
    if (!_signedIn()) return;
    final id = await context.push<String>(RouteNames.republicCompose);
    if (id == null || !mounted) return;
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
    final l10n = context.l10n;
    final feed = ref.watch(feedControllerProvider(_tab));
    final sort = ref.watch(feedSortProvider);
    final term = ref.watch(feedSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Navigator.canPop(context) ? 8 : 16,
                8,
                16,
                0,
              ),
              child: Row(
                children: [
                  // A tab now; the arrow only shows if it was pushed.
                  if (Navigator.canPop(context))
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      l10n.republicTitle,
                      style: AppTypography.display(size: 26),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.republicSearchHint,
                    onPressed: () {
                      if (_searching && _search.text.isNotEmpty) {
                        _clearSearch();
                      }
                      setState(() => _searching = !_searching);
                    },
                    icon: Icon(
                      _searching
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      size: 28,
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
            _FeedTabs(
              tabs: _tabs,
              selected: _tab,
              label: _tabLabel,
              onSelect: (t) => setState(() => _tab = t),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<FeedSort>(
                    tooltip: l10n.republicSortBy,
                    initialValue: sort,
                    onSelected: ref.read(feedSortProvider.notifier).choose,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: FeedSort.recent,
                        child: Text(l10n.republicSortRecent),
                      ),
                      PopupMenuItem(
                        value: FeedSort.top,
                        child: Text(l10n.republicSortTop),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_vert_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sort == FeedSort.top
                              ? l10n.republicSortTop
                              : l10n.republicSortRecent,
                          style: AppTypography.body(
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: feed.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
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
                        return _ComposerRow(onTap: _compose);
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
                        onReact: (r) => unawaited(_actions.react(post.id, r)),
                        onReactions: () =>
                            unawaited(_actions.reactions(post.id)),
                        myUserId: ref.read(authControllerProvider).user?.id,
                        onVote: (o) => unawaited(_actions.vote(post.id, o)),
                        onOpenListing: () => _actions.openListing(post),
                        onMessage: () =>
                            unawaited(_actions.messageAuthor(post)),
                        onShare: () => unawaited(_actions.share(post)),
                        onHashtag: _searchFor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The feed's sections as text across the full width, the open one in the
/// accent colour with a line under it. Fixed rather than scrolling, so every
/// section is in sight.
class _FeedTabs extends StatelessWidget {
  const _FeedTabs({
    required this.tabs,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  final List<String?> tabs;
  final String? selected;
  final String Function(String?) label;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final t in tabs)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == selected,
                child: InkWell(
                  onTap: () => onSelect(t),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 3,
                          color: t == selected
                              ? AppColors.accent
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label(t),
                        style: AppTypography.body(
                          weight: FontWeight.w700,
                          color: t == selected
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
