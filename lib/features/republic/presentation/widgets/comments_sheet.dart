import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What happened while the comments were open, so the post can follow: how
/// many comments were added, and whether any was deleted.
class CommentsResult {
  const CommentsResult({this.added = 0, this.removed = false});

  final int added;
  final bool removed;
}

/// A post's comments: reply, like, edit and delete, with a field to add one.
Future<CommentsResult> showCommentsSheet(
  BuildContext context, {
  required String postId,
  required bool signedIn,
}) async {
  final result = await showModalBottomSheet<CommentsResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _Comments(postId: postId, signedIn: signedIn),
  );
  return result ?? const CommentsResult();
}

enum _CommentMenu { edit, delete }

class _Comments extends ConsumerStatefulWidget {
  const _Comments({required this.postId, required this.signedIn});

  final String postId;
  final bool signedIn;

  @override
  ConsumerState<_Comments> createState() => _CommentsState();
}

class _CommentsState extends ConsumerState<_Comments> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  int _added = 0;
  bool _removed = false;

  /// The top-level comment being replied to, or the one being edited.
  PostComment? _replyTo;
  PostComment? _editing;

  /// Likes the person just tapped, shown before the list is read again:
  /// comment id to (liked, count).
  final _likes = <String, ({bool liked, int count})>{};

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  RepublicRepository get _repo => ref.read(republicRepositoryProvider);

  void _fail(Object e, String fallback) {
    if (!mounted) return;
    showTopToast(context, e is AppException ? e.message : fallback);
  }

  void _clearMode() {
    _replyTo = null;
    _editing = null;
    _field.clear();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final text = _field.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final editing = _editing;
      if (editing != null) {
        await _repo.editComment(widget.postId, editing.id, text);
      } else {
        await _repo.addComment(widget.postId, text, parentId: _replyTo?.id);
        _added++;
      }
      _clearMode();
      ref.invalidate(postCommentsProvider(widget.postId));
    } on Object catch (e) {
      _fail(e, l10n.republicCommentFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _like(PostComment c) async {
    final l10n = context.l10n;
    if (!widget.signedIn) {
      showTopToast(context, l10n.signInToContinue);
      return;
    }
    final before = _likes[c.id] ?? (liked: c.isLikedByMe, count: c.likesCount);
    // Shown at once; put back if the server refuses.
    setState(() {
      _likes[c.id] = (
        liked: !before.liked,
        count: (before.count + (before.liked ? -1 : 1)).clamp(0, 1 << 30),
      );
    });
    try {
      final now = await _repo.toggleCommentLike(widget.postId, c.id);
      if (mounted) setState(() => _likes[c.id] = now);
    } on Object {
      if (mounted) {
        setState(() => _likes[c.id] = before);
        showTopToast(context, l10n.republicLikeFailed);
      }
    }
  }

  void _reply(PostComment c) {
    setState(() {
      _clearMode();
      _replyTo = c;
    });
    _focus.requestFocus();
  }

  void _edit(PostComment c) {
    setState(() {
      _clearMode();
      _editing = c;
      _field.text = c.content;
    });
    _focus.requestFocus();
  }

  Future<void> _delete(PostComment c) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.republicDeleteCommentTitle),
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
    if (sure != true || !mounted) return;
    try {
      await _repo.deleteComment(widget.postId, c.id);
      _removed = true;
      if (_editing?.id == c.id || _replyTo?.id == c.id) {
        setState(_clearMode);
      }
      ref.invalidate(postCommentsProvider(widget.postId));
    } on Object catch (e) {
      _fail(e, l10n.republicActionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final comments = ref.watch(postCommentsProvider(widget.postId));
    final me = ref.watch(authControllerProvider.select((s) => s.user?.id));

    Widget row(PostComment c, {required bool isReply}) => _CommentRow(
          comment: c,
          locale: locale,
          isReply: isReply,
          isMine: me != null && me == c.author.id,
          likes: _likes[c.id] ?? (liked: c.isLikedByMe, count: c.likesCount),
          canReply: widget.signedIn && !isReply,
          onLike: () => _like(c),
          onReply: () => _reply(c),
          onMenu: (action) => switch (action) {
            _CommentMenu.edit => _edit(c),
            _CommentMenu.delete => _delete(c),
          },
        );

    final banner = _editing != null
        ? l10n.republicEditingComment
        : _replyTo != null
            ? l10n.republicReplyingTo(_replyTo!.author.name)
            : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(
            context,
            CommentsResult(added: _added, removed: _removed),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.republicComments,
                    style: AppTypography.display(size: 20),
                  ),
                ),
              ),
              Expanded(
                child: comments.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (_, __) => Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(postCommentsProvider(widget.postId)),
                      child: Text(l10n.retry),
                    ),
                  ),
                  data: (list) => list.isEmpty
                      ? Center(
                          child: Text(
                            l10n.republicNoComments,
                            style:
                                AppTypography.body(color: AppColors.textMuted),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: [
                            for (final c in list) ...[
                              row(c, isReply: false),
                              for (final r in c.replies)
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: row(r, isReply: true),
                                ),
                            ],
                          ],
                        ),
                ),
              ),
              if (widget.signedIn) ...[
                if (banner != null)
                  Container(
                    color: AppColors.canvas,
                    padding: const EdgeInsets.fromLTRB(20, 4, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            banner,
                            style: AppTypography.body(
                              size: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: () => setState(_clearMode),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _field,
                          focusNode: _focus,
                          maxLength: 1000,
                          buildCounter: (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) =>
                              null,
                          decoration: InputDecoration(
                            hintText: l10n.republicCommentHint,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.republicSend,
                        onPressed: _busy ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Text(
                    l10n.signInToContinue,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.locale,
    required this.isReply,
    required this.isMine,
    required this.likes,
    required this.canReply,
    required this.onLike,
    required this.onReply,
    required this.onMenu,
  });

  final PostComment comment;
  final String locale;
  final bool isReply;
  final bool isMine;
  final ({bool liked, int count}) likes;
  final bool canReply;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final ValueChanged<_CommentMenu> onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final age = postAge(l10n, comment.createdAt, locale);
    final small = AppTypography.body(size: 12, color: AppColors.textMuted);
    final action = AppTypography.body(
      size: 12,
      weight: FontWeight.w700,
      color: AppColors.textMuted,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorAvatar(author: comment.author, size: isReply ? 26 : 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.author.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(comment.content, style: AppTypography.body()),
                        ],
                      ),
                    ),
                    if (likes.count > 0)
                      Positioned(
                        right: 8,
                        bottom: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 12,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 3),
                              Text('${likes.count}', style: small),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    top: likes.count > 0 ? 14 : 4,
                  ),
                  child: Wrap(
                    spacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (age.isNotEmpty) Text(age, style: small),
                      if (comment.edited)
                        Text(l10n.republicEdited, style: small),
                      GestureDetector(
                        onTap: onLike,
                        child: Text(
                          l10n.republicLike,
                          style: action.copyWith(
                            color: likes.liked
                                ? AppColors.accent
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (canReply)
                        GestureDetector(
                          onTap: onReply,
                          child: Text(l10n.republicReply, style: action),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMine)
            PopupMenuButton<_CommentMenu>(
              tooltip: l10n.republicMore,
              icon: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              onSelected: onMenu,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _CommentMenu.edit,
                  child: Text(l10n.republicEditComment),
                ),
                PopupMenuItem(
                  value: _CommentMenu.delete,
                  child: Text(l10n.republicDeleteComment),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
