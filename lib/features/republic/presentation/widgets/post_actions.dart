import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';
import 'package:flutter_template/features/republic/presentation/widgets/comments_sheet.dart';
import 'package:flutter_template/features/republic/presentation/widgets/compose_sheet.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_menu_sheet.dart';
import 'package:flutter_template/features/republic/presentation/widgets/reaction_picker.dart';
import 'package:flutter_template/features/republic/presentation/widgets/share_sheets.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/blocks/confirm_block.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:go_router/go_router.dart';

/// What a person can do with a post in a feed list, shared by the Republic
/// and the Saved posts so both behave the same. [tab] picks the feed whose
/// list is updated (`null` is all, [RepublicRepository.savedTab] is Saved).
class PostActions {
  PostActions(this.context, this.ref, this.tab);

  final BuildContext context;
  final WidgetRef ref;
  final String? tab;

  FeedController get _feed => ref.read(feedControllerProvider(tab).notifier);

  bool _signedIn() {
    if (ref.read(authControllerProvider).user != null) return true;
    showTopToast(context, context.l10n.signInToContinue);
    return false;
  }

  Future<void> like(String postId) async {
    if (!_signedIn()) return;
    final ok = await _feed.toggleLike(postId);
    if (!ok && context.mounted) {
      showTopToast(context, context.l10n.republicLikeFailed);
    }
  }

  Future<void> react(String postId, ReactionType type) async {
    if (!_signedIn()) return;
    final ok = await _feed.react(postId, type);
    if (!ok && context.mounted) {
      showTopToast(context, context.l10n.republicLikeFailed);
    }
  }

  Future<void> vote(String postId, String optionId) async {
    if (!_signedIn()) return;
    final ok = await _feed.vote(postId, optionId);
    if (!ok && context.mounted) {
      showTopToast(context, context.l10n.republicVoteFailed);
    }
  }

  /// Opens the venue, gear, service or event a post advertises.
  void openListing(Post post) {
    final item = post.listing;
    if (item == null) return;
    unawaited(
      switch (item.kind) {
        CatalogKind.venues => context.push(RouteNames.venueDetail, extra: item),
        CatalogKind.events =>
          context.push(RouteNames.scheduledEventDetail, extra: item),
        _ => context.push(RouteNames.itemBooking, extra: item),
      },
    );
  }

  /// Starts a chat with the post's author.
  Future<void> messageAuthor(Post post) async {
    if (!_signedIn()) return;
    final me = ref.read(authControllerProvider).user;
    if (me != null && me.id == post.author.id) return;
    final l10n = context.l10n;
    try {
      final id = await ref
          .read(messagesRepositoryProvider)
          .startWithUser(post.author.id);
      ref.invalidate(conversationsProvider);
      if (context.mounted) unawaited(context.push(RouteNames.chat(id)));
    } on Object catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.messageStartFailed,
        );
      }
    }
  }

  Future<void> reactions(String postId) =>
      showReactionBreakdown(context, postId);

  Future<void> comments(String postId) async {
    final result = await showCommentsSheet(
      context,
      postId: postId,
      signedIn: ref.read(authControllerProvider).user != null,
    );
    for (var i = 0; i < result.added; i++) {
      _feed.commentAdded(postId);
    }
    if (result.removed) await _feed.reload(postId);
  }

  /// The link to a post on the web, or null when the app has no web address.
  String? _link(Post post) {
    final base = AppConfig.instance.webAppUrl;
    if (base.isEmpty) return null;
    final trimmed =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$trimmed/republic?postId=${post.id}';
  }

  /// Share: repost onto your own feed, send in a chat, or copy the link.
  Future<void> share(Post post) async {
    if (!_signedIn()) return;
    final l10n = context.l10n;
    final action = await showShareSheet(
      context,
      // A repost cannot be reposted; share the original instead.
      canRepost: post.original == null,
      canCopyLink: _link(post) != null,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case ShareAction.repost:
        final caption = await showComposeSheet(
          context,
          title: l10n.republicRepostTitle,
          action: l10n.republicRepost,
          hint: l10n.republicRepostHint,
          allowEmpty: true,
        );
        if (caption == null || !context.mounted) return;
        await _run(
          () async {
            await ref.read(republicRepositoryProvider).repost(post.id, caption);
            await _feed.refresh();
          },
          l10n.republicReposted,
        );
      case ShareAction.send:
        final sent = await showSendPostSheet(context, post);
        if (sent > 0 && context.mounted) {
          showTopToast(
            context,
            sent == 1 ? l10n.republicPostSent : l10n.republicPostSentMany(sent),
          );
        }
      case ShareAction.copyLink:
        final link = _link(post);
        if (link == null) return;
        await Clipboard.setData(ClipboardData(text: link));
        if (context.mounted) showTopToast(context, l10n.republicLinkCopied);
    }
  }

  /// The ⋯ menu of [post] and whatever the person picks from it.
  Future<void> menu(Post post) async {
    final me = ref.read(authControllerProvider).user;
    final base = AppConfig.instance.webAppUrl;
    final action = await showPostMenu(
      context,
      isOwner: me != null && me.id == post.author.id,
      saved: post.isSavedByMe,
      canCopyLink: base.isNotEmpty,
      authorName: post.author.name,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case PostMenuAction.copyLink:
        final trimmed =
            base.endsWith('/') ? base.substring(0, base.length - 1) : base;
        await Clipboard.setData(
          ClipboardData(text: '$trimmed/republic?postId=${post.id}'),
        );
        if (context.mounted) {
          showTopToast(context, context.l10n.republicLinkCopied);
        }
      case PostMenuAction.save:
        if (!_signedIn()) return;
        final wasSaved = post.isSavedByMe;
        final ok = await _feed.toggleSave(post.id);
        if (!context.mounted) return;
        showTopToast(
          context,
          !ok
              ? context.l10n.republicActionFailed
              : wasSaved
                  ? context.l10n.republicUnsaved
                  : context.l10n.republicSaved,
        );
      case PostMenuAction.edit:
        await _edit(post);
      case PostMenuAction.delete:
        await _delete(post);
      case PostMenuAction.hide:
        if (!_signedIn()) return;
        await _run(() => _feed.hide(post.id), context.l10n.republicHidden);
      case PostMenuAction.block:
        if (!_signedIn()) return;
        final blocked = await confirmBlock(
          context,
          ref,
          userId: post.author.id,
          name: post.author.name,
        );
        // Their posts leave the feed once they are blocked.
        if (blocked) await _feed.refresh();
      case PostMenuAction.report:
        if (!_signedIn()) return;
        final reason = await showReportSheet(context);
        if (reason == null || !context.mounted) return;
        await _run(
          () => ref.read(republicRepositoryProvider).report(post.id, reason),
          context.l10n.republicReported,
        );
    }
  }

  Future<void> _edit(Post post) async {
    final l10n = context.l10n;
    final text = await showComposeSheet(
      context,
      initial: post.content,
      title: l10n.republicEditTitle,
      action: l10n.republicEditSave,
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await _run(() => _feed.edit(post.id, text), l10n.republicUpdated);
  }

  Future<void> _delete(Post post) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.republicDeleteTitle),
        content: Text(l10n.republicDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.republicCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.republicDeleteConfirm),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    await _run(() => _feed.delete(post.id), l10n.republicDeleted);
  }

  /// Runs [job], then says [done], or why it did not work.
  Future<void> _run(Future<void> Function() job, String done) async {
    final l10n = context.l10n;
    try {
      await job();
      if (context.mounted) showTopToast(context, done);
    } on Object catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.republicActionFailed,
        );
      }
    }
  }
}
