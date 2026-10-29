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

/// One post on its own, for when a link or a notification points at it. It
/// does everything the post does in the feed, and opens its comments at once
/// when [openComments] is set.
class PostPage extends ConsumerStatefulWidget {
  const PostPage({required this.postId, this.openComments = false, super.key});

  final String postId;
  final bool openComments;

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  late final String _tab = RepublicRepository.postTab(widget.postId);
  bool _opened = false;

  PostActions get _actions => PostActions(context, ref, _tab);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(feedControllerProvider(_tab));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l10n.republicPostTitle)),
      body: feed.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(feedControllerProvider(_tab)),
        ),
        data: (state) {
          if (state.posts.isEmpty) {
            return AppStateView(
              title: l10n.republicPostGone,
              message: l10n.republicPostGoneBody,
              icon: Icons.speaker_notes_off_outlined,
            );
          }
          final post = state.posts.first;
          if (widget.openComments && !_opened) {
            _opened = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_actions.comments(post.id));
            });
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () =>
                ref.read(feedControllerProvider(_tab).notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PostCard(
                  post: post,
                  onLike: () => unawaited(_actions.like(post.id)),
                  onComments: () => unawaited(_actions.comments(post.id)),
                  onMore: () => unawaited(_actions.menu(post)),
                  onReact: (r) => unawaited(_actions.react(post.id, r)),
                  onReactions: () => unawaited(_actions.reactions(post.id)),
                  myUserId: ref.read(authControllerProvider).user?.id,
                  onVote: (o) => unawaited(_actions.vote(post.id, o)),
                  onOpenListing: () => _actions.openListing(post),
                  onMessage: () => unawaited(_actions.messageAuthor(post)),
                  onShare: () => unawaited(_actions.share(post)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
