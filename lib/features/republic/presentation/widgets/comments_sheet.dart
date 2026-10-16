import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A post's comments, with a field to add one. Resolves how many comments the
/// person added while it was open.
Future<int> showCommentsSheet(
  BuildContext context, {
  required String postId,
  required bool signedIn,
}) async {
  final added = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _Comments(postId: postId, signedIn: signedIn),
  );
  return added ?? 0;
}

class _Comments extends ConsumerStatefulWidget {
  const _Comments({required this.postId, required this.signedIn});

  final String postId;
  final bool signedIn;

  @override
  ConsumerState<_Comments> createState() => _CommentsState();
}

class _CommentsState extends ConsumerState<_Comments> {
  final _field = TextEditingController();
  bool _busy = false;
  int _added = 0;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final text = _field.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(republicRepositoryProvider).addComment(
            widget.postId,
            text,
          );
      _field.clear();
      _added++;
      ref.invalidate(postCommentsProvider(widget.postId));
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.republicCommentFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final comments = ref.watch(postCommentsProvider(widget.postId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _added);
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          children: [
                            for (final c in list) ...[
                              _CommentRow(comment: c, locale: locale),
                              for (final r in c.replies)
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: _CommentRow(
                                    comment: r,
                                    locale: locale,
                                    small: true,
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
              ),
              if (widget.signedIn)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _field,
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
                )
              else
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
    this.small = false,
  });

  final PostComment comment;
  final String locale;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final age = postAge(l10n, comment.createdAt, locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorAvatar(author: comment.author, size: small ? 26 : 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(weight: FontWeight.w600),
                      ),
                    ),
                    if (age.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        age,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content, style: AppTypography.body()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
