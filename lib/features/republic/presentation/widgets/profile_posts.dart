import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_actions.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One person's posts, as a feed: the same cards as the Republic, with Like,
/// reactions, Comments, Share and the more menu. Meant to sit inside a page
/// that already scrolls, so it takes its height from its posts.
class ProfilePosts extends ConsumerWidget {
  const ProfilePosts({required this.authorId, super.key});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tab = RepublicRepository.authorTab(authorId);
    final async = ref.watch(feedControllerProvider(tab));
    final actions = PostActions(context, ref, tab);
    final me = ref.read(authControllerProvider).user?.id;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (_, __) => AppStateView(
        kind: AppStateKind.error,
        title: l10n.apiLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(feedControllerProvider(tab)),
      ),
      data: (state) {
        if (state.posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(l10n.citizenNoPosts, style: AppTypography.display()),
                const SizedBox(height: 4),
                Text(
                  l10n.citizenNoPostsBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  for (var i = 0; i < state.posts.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 8,
                        thickness: 8,
                        color: AppColors.surface,
                      ),
                    Builder(
                      builder: (_) {
                        final post = state.posts[i];
                        return PostCard(
                          post: post,
                          onLike: () => unawaited(actions.like(post.id)),
                          onComments: () =>
                              unawaited(actions.comments(post.id)),
                          onMore: () => unawaited(actions.menu(post)),
                          onReact: (r) => unawaited(actions.react(post.id, r)),
                          onReactions: () =>
                              unawaited(actions.reactions(post.id)),
                          myUserId: me,
                          onVote: (o) => unawaited(actions.vote(post.id, o)),
                          onOpenListing: () => actions.openListing(post),
                          onMessage: () =>
                              unawaited(actions.messageAuthor(post)),
                          onShare: () => unawaited(actions.share(post)),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (state.hasMore || state.loadMoreFailed)
              TextButton(
                onPressed: () => unawaited(
                  ref.read(feedControllerProvider(tab).notifier).loadMore(),
                ),
                child: Text(
                  state.loadMoreFailed ? l10n.retry : l10n.citizenLoadMore,
                ),
              ),
          ],
        );
      },
    );
  }
}
