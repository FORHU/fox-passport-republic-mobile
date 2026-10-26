import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/compose_sheet.dart';
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
  static const _tabs = <String?>[null, 'community', 'marketplace'];

  String? _tab;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
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

  Future<void> _compose() async {
    if (!_signedIn()) return;
    final l10n = context.l10n;
    final text = await showComposeSheet(context);
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      await ref.read(republicRepositoryProvider).createPost(text);
      if (!mounted) return;
      showTopToast(context, l10n.republicPosted);
      await ref.read(feedControllerProvider(_tab).notifier).refresh();
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.republicPostFailed,
        );
      }
    }
  }

  String _tabLabel(String? tab) {
    final l10n = context.l10n;
    return switch (tab) {
      'community' => l10n.republicTabCommunity,
      'marketplace' => l10n.republicTabMarketplace,
      _ => l10n.republicTabAll,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(feedControllerProvider(_tab));

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
                    tooltip: l10n.republicSavedOpen,
                    onPressed: () =>
                        unawaited(context.push(RouteNames.republicSaved)),
                    icon: const Icon(Icons.bookmark_border_rounded, size: 28),
                  ),
                  IconButton(
                    tooltip: l10n.republicCompose,
                    onPressed: _compose,
                    icon: const Icon(Icons.add_box_outlined, size: 28),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final t in _tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: ChoiceChip(
                          label: Text(_tabLabel(t)),
                          selected: _tab == t,
                          onSelected: (_) => setState(() => _tab = t),
                        ),
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
                                child: Text(
                                  l10n.republicEmpty,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body(
                                    color: AppColors.textMuted,
                                  ),
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
