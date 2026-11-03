import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What the Share button offers.
enum ShareAction { repost, send, copyLink }

/// Share a post: onto your own feed, to people in a chat, or as a link.
/// Resolves what was chosen, or null.
Future<ShareAction?> showShareSheet(
  BuildContext context, {
  required bool canRepost,
  required bool canCopyLink,
}) {
  final l10n = context.l10n;
  Widget row(IconData icon, String label, ShareAction action) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: () => Navigator.pop(context, action),
      );

  return showModalBottomSheet<ShareAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canRepost)
          row(Icons.repeat_rounded, l10n.republicRepost, ShareAction.repost),
        row(Icons.send_outlined, l10n.republicSendInMessage, ShareAction.send),
        if (canCopyLink)
          row(
            Icons.link_rounded,
            l10n.republicMenuCopyLink,
            ShareAction.copyLink,
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// Pick people you already chat with, add a line, and send them [post].
/// Resolves how many chats it went to (0 when closed).
Future<int> showSendPostSheet(BuildContext context, Post post) async {
  final sent = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _SendPost(post: post),
  );
  return sent ?? 0;
}

class _SendPost extends ConsumerStatefulWidget {
  const _SendPost({required this.post});

  final Post post;

  @override
  ConsumerState<_SendPost> createState() => _SendPostState();
}

class _SendPostState extends ConsumerState<_SendPost> {
  final _caption = TextEditingController();
  final _selected = <String>{};
  String _query = '';
  bool _sending = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    if (_selected.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final repo = ref.read(messagesRepositoryProvider);
      for (final id in _selected) {
        await repo.sendMessage(
          id,
          _caption.text.trim(),
          sharedPostId: widget.post.id,
        );
      }
      ref.invalidate(conversationsProvider);
      if (mounted) Navigator.pop(context, _selected.length);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showTopToast(
          context,
          e is AppException ? e.message : l10n.republicSendPostFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chats = ref.watch(conversationsProvider);
    final post = widget.post;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  AuthorAvatar(author: post.author, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.republicSendPostTitle,
                          style: AppTypography.display(size: 18),
                        ),
                        Text(
                          post.content.isEmpty
                              ? post.author.name
                              : '${post.author.name}: ${post.content}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.republicSendSearch,
                ),
              ),
            ),
            Expanded(
              child: chats.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(conversationsProvider),
                    child: Text(l10n.retry),
                  ),
                ),
                data: (all) {
                  final list = [
                    for (final c in all)
                      if (!c.isInbox &&
                          c.status == 'accepted' &&
                          c.title.toLowerCase().contains(_query))
                        c,
                  ];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.republicSendNoChats,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }
                  return ListView(
                    children: [for (final c in list) _chatRow(c)],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caption,
                      maxLength: 500,
                      buildCounter: (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null,
                      decoration: InputDecoration(
                        hintText: l10n.republicSendCaptionHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: _selected.isEmpty || _sending ? null : _send,
                    child: Text(l10n.republicSend),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatRow(Conversation c) {
    final on = _selected.contains(c.id);
    return CheckboxListTile(
      value: on,
      onChanged: _sending
          ? null
          : (v) => setState(() {
                if (v ?? false) {
                  _selected.add(c.id);
                } else {
                  _selected.remove(c.id);
                }
              }),
      secondary: AvatarImage(
        url: c.avatarUrl,
        radius: 20,
        fallback: Text(
          c.title.isEmpty ? '?' : c.title.characters.first.toUpperCase(),
        ),
      ),
      title: Text(c.title),
      activeColor: AppColors.accent,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
