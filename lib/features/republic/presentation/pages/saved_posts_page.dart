import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/post_view_tracker.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/widgets/feed_skeleton.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_actions.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The posts this person saved, newest first. Unsaving one takes it off the
/// list; swiping a post away unsaves it, with a way to undo.
class SavedPostsPage extends ConsumerStatefulWidget {
  const SavedPostsPage({super.key});

  @override
  ConsumerState<SavedPostsPage> createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends ConsumerState<SavedPostsPage> {
  static const String _tab = RepublicRepository.savedTab;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        unawaited(ref.read(feedControllerProvider(_tab).notifier).loadMore());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// A swiped-away post leaves the list at once and is unsaved on the server;
  /// Undo saves it again and reloads the list. If the server refuses, the
  /// list is reloaded so the post comes back.
  Future<void> _unsave(String postId) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(republicRepositoryProvider);
    final notifier = ref.read(feedControllerProvider(_tab).notifier);
    try {
      await repository.toggleSave(postId);
    } on Object {
      // Let the swiped row leave the tree first; a reload that brought it back
      // in the same frame would leave a dismissed row on screen.
      await WidgetsBinding.instance.endOfFrame;
      await notifier.refresh();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.republicActionFailed)));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.republicUnsaved),
          action: SnackBarAction(
            label: l10n.republicUndo,
            onPressed: () => unawaited(_undo(postId)),
          ),
        ),
      );
  }

  Future<void> _undo(String postId) async {
    final repository = ref.read(republicRepositoryProvider);
    final notifier = ref.read(feedControllerProvider(_tab).notifier);
    try {
      await repository.toggleSave(postId);
    } on Object {
      // Nothing to show: the list below is the truth after the reload.
    }
    await notifier.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(feedControllerProvider(_tab));
    final actions = PostActions(context, ref, _tab);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(l10n.republicSavedTitle)),
      body: feed.when(
        loading: () => const FeedSkeleton(),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(feedControllerProvider(_tab)),
        ),
        data: (state) => state.posts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bookmark_border_rounded,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.republicSavedEmpty,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go(RouteNames.republic),
                        child: Text(l10n.passportSavedAction),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () =>
                    ref.read(feedControllerProvider(_tab).notifier).refresh(),
                child: ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: state.posts.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 8,
                    thickness: 8,
                    color: AppColors.surface,
                  ),
                  itemBuilder: (context, i) {
                    final post = state.posts[i];
                    return Dismissible(
                      key: ValueKey('saved-${post.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(
                          Icons.bookmark_remove_outlined,
                          color: AppColors.canvas,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(feedControllerProvider(_tab).notifier)
                            .removeLocally(post.id);
                        unawaited(_unsave(post.id));
                      },
                      child: PostCard(
                        post: post,
                        onSeen: () => ref
                            .read(postViewTrackerProvider)
                            ?.seen(post.id, authorId: post.author.id),
                        onLike: () => unawaited(actions.like(post.id)),
                        onComments: () => unawaited(actions.comments(post.id)),
                        onMore: () => unawaited(actions.menu(post)),
                        onAuthor: () => unawaited(
                          context.push(RouteNames.citizen(post.author.id)),
                        ),
                        onReact: (r) => unawaited(actions.react(post.id, r)),
                        onReactions: () =>
                            unawaited(actions.reactions(post.id)),
                        myUserId: ref.read(authControllerProvider).user?.id,
                        onVote: (o) => unawaited(actions.vote(post.id, o)),
                        onOpenListing: () => actions.openListing(post),
                        onMessage: () => unawaited(actions.messageAuthor(post)),
                        onShare: () => unawaited(actions.share(post)),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
