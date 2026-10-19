import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_realtime.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The emoji offered on a long press.
const _reactionEmoji = ['👍', '❤️', '😂', '🎉', '🙏'];

class MessagesChatPage extends ConsumerStatefulWidget {
  const MessagesChatPage({
    required this.conversationId,
    this.conversation,
    super.key,
  });

  final String conversationId;
  final Conversation? conversation;

  @override
  ConsumerState<MessagesChatPage> createState() => _MessagesChatPageState();
}

class _MessagesChatPageState extends ConsumerState<MessagesChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _requestResolved = false;

  /// The message being replied to, or edited, shown above the composer.
  ChatMessage? _replyTo;
  ChatMessage? _editing;

  /// A photo chosen but not yet sent.
  PickedPhoto? _photo;

  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref
          .read(messagesRepositoryProvider)
          .markRead(widget.conversationId);
      ref.invalidate(conversationsProvider);
    } on AppException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conversations = ref.watch(conversationsProvider).asData?.value;
    // The list is the fresher source (mute and pin change it); the route's
    // copy covers the moment before the list has loaded.
    final conversation = conversations
            ?.where((item) => item.id == widget.conversationId)
            .firstOrNull ??
        widget.conversation;
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    if (conversation == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Center(
            child: Text(l10n.messagesLoadFailed, style: AppTypography.body()),
          ),
        ),
      );
    }

    final isRequest = conversation.isIncomingRequest &&
        conversation.hasPendingRequest &&
        !_requestResolved;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _ChatAvatar(
              name: conversation.title,
              group: conversation.isGroup,
              online: conversation.otherUserOnline,
              imageUrl: conversation.avatarUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(size: 14),
                        ),
                      ),
                      if (conversation.otherUserVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  if (!conversation.isGroup && !conversation.isInbox)
                    _Subtitle(conversation: conversation),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<_ChatMenu>(
            tooltip: l10n.messageMore,
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.surfaceRaised,
            onSelected: (item) => _onMenu(item, conversation),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ChatMenu.mute,
                child: Text(
                  conversation.isMuted ? l10n.messageUnmute : l10n.messageMute,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
              ),
              PopupMenuItem(
                value: _ChatMenu.pin,
                child: Text(
                  conversation.isPinned
                      ? l10n.messageUnpinChat
                      : l10n.messagePinChat,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (conversation.contextLabel != null)
              _BookingContext(
                label: conversation.contextLabel!,
                onTap: () => context.go(RouteNames.tickets),
              ),
            Expanded(
              child: messages.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.messagesLoadFailed,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          chatMessagesProvider(widget.conversationId),
                        ),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  final sorted = [...items]
                    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  if (sorted.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.messagesEmpty,
                        style: AppTypography.body(color: AppColors.textMuted),
                      ),
                    );
                  }
                  final lastOutgoingIndex = currentUserId == null
                      ? -1
                      : sorted.lastIndexWhere(
                          (message) => message.senderId == currentUserId,
                        );
                  final messageWidgets = <Widget>[];
                  DateTime? previousDate;
                  for (var index = 0; index < sorted.length; index++) {
                    final message = sorted[index];
                    final date = message.createdAt.toLocal();
                    if (previousDate == null ||
                        !_sameDate(previousDate, date)) {
                      messageWidgets.add(
                        _DateSeparator(
                          label: _dateLabel(context, date, l10n.ticketToday),
                        ),
                      );
                    }
                    final mine = message.senderId == currentUserId;
                    messageWidgets.add(
                      _MessageBubble(
                        message: message,
                        isMine: mine,
                        onLongPress: message.isSystem
                            ? null
                            : () => _showActions(message, mine: mine),
                      ),
                    );
                    if (index == lastOutgoingIndex && message.isRead) {
                      messageWidgets.add(
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8, right: 8),
                            child: Text(
                              l10n.messageSeen,
                              style: AppTypography.label(),
                            ),
                          ),
                        ),
                      );
                    }
                    previousDate = date;
                  }
                  // Reversed, so the newest message sits at the bottom and a
                  // short conversation is anchored there, as in any chat.
                  return ListView(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: messageWidgets.reversed.toList(),
                  );
                },
              ),
            ),
            if (isRequest)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _resolveRequest(accept: false),
                        child: Text(l10n.messageRequestDecline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                        ),
                        onPressed: () => _resolveRequest(accept: true),
                        child: Text(l10n.messageRequestAccept),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (_replyTo != null || _editing != null)
                _ComposerBanner(
                  title: _editing != null
                      ? l10n.messageEditing
                      : l10n.messageReplyingTo,
                  text: (_editing ?? _replyTo)!.content,
                  onCancel: _clearComposerMode,
                ),
              if (_photo != null)
                _PhotoBanner(
                  photo: _photo!,
                  onRemove: () => setState(() => _photo = null),
                ),
              _Composer(
                controller: _messageController,
                sending: _sending,
                onSend: _send,
                onAttach: _pickPhoto,
                onChanged: _signalTyping,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearComposerMode() {
    setState(() {
      if (_editing != null) _messageController.clear();
      _replyTo = null;
      _editing = null;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await ref.read(photoPickerProvider).pick();
      if (photo != null && mounted) {
        setState(() {
          _photo = photo;
          _editing = null;
        });
      }
    } on Object {
      if (mounted) _showError(context.l10n.messageUploadFailed);
    }
  }

  /// Tells the other person we are typing, at most every few seconds.
  void _signalTyping(String text) {
    if (text.isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < const Duration(seconds: 3)) return;
    _lastTypingSent = now;
    ref.read(realtimeServiceProvider)?.emit(
      RealtimeEvents.typing,
      {'conversationId': widget.conversationId},
    );
  }

  Future<void> _send() async {
    final content = _messageController.text.trim();
    final photo = _photo;
    if ((content.isEmpty && photo == null) || _sending) return;
    final repository = ref.read(messagesRepositoryProvider);
    final editing = _editing;
    final replyTo = _replyTo;
    setState(() => _sending = true);
    try {
      if (editing != null) {
        await repository.editMessage(
          widget.conversationId,
          editing.id,
          content,
        );
      } else {
        final url = photo == null ? null : await repository.uploadPhoto(photo);
        await repository.sendMessage(
          widget.conversationId,
          content,
          replyToId: replyTo?.id,
          attachmentUrls: [if (url != null) url],
        );
      }
      _messageController.clear();
      if (mounted) {
        setState(() {
          _replyTo = null;
          _editing = null;
          _photo = null;
        });
      }
      ref
        ..invalidate(chatMessagesProvider(widget.conversationId))
        ..invalidate(conversationsProvider);
    } on AppException catch (error) {
      if (mounted) _showError(error.message);
    } on Object {
      if (mounted) _showError(context.l10n.messageUploadFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showActions(ChatMessage message, {required bool mine}) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final emoji in _reactionEmoji)
                    InkWell(
                      borderRadius: AppRadius.brPill,
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_MessageAction.react(emoji)),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                ],
              ),
              const Divider(color: AppColors.border),
              _ActionTile(
                icon: Icons.reply_rounded,
                label: l10n.messageReply,
                onTap: () => Navigator.of(sheetContext)
                    .pop(const _MessageAction.reply()),
              ),
              if (mine && message.content.isNotEmpty)
                _ActionTile(
                  icon: Icons.edit_outlined,
                  label: l10n.messageEdit,
                  onTap: () => Navigator.of(sheetContext)
                      .pop(const _MessageAction.edit()),
                ),
              if (mine)
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: l10n.messageDelete,
                  danger: true,
                  onTap: () => Navigator.of(sheetContext)
                      .pop(const _MessageAction.delete()),
                ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    final repository = ref.read(messagesRepositoryProvider);
    try {
      switch (action.kind) {
        case _ActionKind.reply:
          setState(() {
            _editing = null;
            _replyTo = message;
          });
        case _ActionKind.edit:
          setState(() {
            _replyTo = null;
            _editing = message;
            _messageController.text = message.content;
          });
        case _ActionKind.delete:
          final confirmed = await _confirmDelete();
          if (confirmed != true) return;
          await repository.deleteMessage(widget.conversationId, message.id);
          ref.invalidate(chatMessagesProvider(widget.conversationId));
        case _ActionKind.react:
          final already = message.reactions.any((r) => r.emoji == action.emoji);
          await repository.react(
            widget.conversationId,
            message.id,
            already ? null : action.emoji,
          );
          ref.invalidate(chatMessagesProvider(widget.conversationId));
      }
    } on AppException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<bool?> _confirmDelete() {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.messageDeletedConfirm,
          style: AppTypography.display(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.messageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.messageDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMenu(_ChatMenu item, Conversation conversation) async {
    final repository = ref.read(messagesRepositoryProvider);
    try {
      switch (item) {
        case _ChatMenu.mute:
          await repository.setMuted(
            widget.conversationId,
            muted: !conversation.isMuted,
          );
        case _ChatMenu.pin:
          await repository.setPinned(
            widget.conversationId,
            pinned: !conversation.isPinned,
          );
      }
      ref.invalidate(conversationsProvider);
    } on AppException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  Future<void> _resolveRequest({required bool accept}) async {
    try {
      final repository = ref.read(messagesRepositoryProvider);
      if (accept) {
        await repository.acceptRequest(widget.conversationId);
      } else {
        await repository.declineRequest(widget.conversationId);
      }
      if (!mounted) return;
      setState(() => _requestResolved = true);
      ref.invalidate(conversationsProvider);
      if (!accept) context.pop();
    } on AppException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  void _showError(String message) => showTopToast(context, message);

  bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  String _dateLabel(BuildContext context, DateTime date, String todayLabel) {
    final now = DateTime.now();
    return _sameDate(date, now)
        ? todayLabel
        : DateFormat.MMMd(Localizations.localeOf(context).toString())
            .format(date);
  }
}

enum _ChatMenu { mute, pin }

enum _ActionKind { react, reply, edit, delete }

class _MessageAction {
  const _MessageAction.reply()
      : kind = _ActionKind.reply,
        emoji = null;
  const _MessageAction.edit()
      : kind = _ActionKind.edit,
        emoji = null;
  const _MessageAction.delete()
      : kind = _ActionKind.delete,
        emoji = null;
  const _MessageAction.react(String this.emoji) : kind = _ActionKind.react;

  final _ActionKind kind;
  final String? emoji;
}

class _Subtitle extends ConsumerWidget {
  const _Subtitle({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final role = foxerRoleLabel(l10n, conversation.otherUserRoles);
    final typing = ref.watch(typingProvider).contains(conversation.id);
    final text = typing
        ? l10n.messageTyping
        : [
            if (role != null) role,
            if (conversation.otherUserOnline) l10n.messageOnline,
          ].join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.body(
        size: 11,
        color: typing || conversation.otherUserOnline
            ? AppColors.roleLabel
            : AppColors.textMuted,
      ),
    );
  }
}

class _BookingContext extends StatelessWidget {
  const _BookingContext({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.messageBookingAbout.toUpperCase(),
                        style: AppTypography.label(),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(size: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.messageViewTicket,
                  style: AppTypography.display(
                    size: 12,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Center(
          child: Text(label.toUpperCase(), style: AppTypography.label()),
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: AppTypography.body(size: 11, color: AppColors.textMuted),
          ),
        ),
      );
    }
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final background = isMine ? AppColors.accentTintBg : AppColors.surface;
    final borderColor = isMine ? AppColors.accentTintBorder : AppColors.border;
    final time = DateFormat.jm(locale).format(message.createdAt.toLocal());
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyToContent != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                  child: Text(
                    message.replyToContent!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              if (message.content.isNotEmpty)
                Text(
                  message.content,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final reaction in message.reactions)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: AppRadius.brPill,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${reaction.emoji} ${reaction.count}',
                          style: AppTypography.body(size: 11),
                        ),
                      ),
                  ],
                ),
              ],
              for (final url in message.attachmentUrls)
                ClipRRect(
                  borderRadius: AppRadius.brSm,
                  child: Container(
                    width: 150,
                    height: 90,
                    margin: const EdgeInsets.only(top: 6),
                    color: AppColors.surfaceRaised,
                    child: Image.network(
                      resolveAssetUrl(url),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                message.isEdited ? '$time · ${l10n.messageEditedSuffix}' : time,
                style: AppTypography.label(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: AppTypography.body(color: color)),
      onTap: onTap,
    );
  }
}

class _PhotoBanner extends StatelessWidget {
  const _PhotoBanner({required this.photo, required this.onRemove});

  final PickedPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              photo.bytes,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              photo.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(size: 13),
            ),
          ),
          IconButton(
            tooltip: context.l10n.messageCancel,
            onPressed: onRemove,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ComposerBanner extends StatelessWidget {
  const _ComposerBanner({
    required this.title,
    required this.text,
    required this.onCancel,
  });

  final String title;
  final String text;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTypography.label()),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(size: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.messageCancelReply,
            onPressed: onCancel,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttach,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          Tooltip(
            message: l10n.messageAttachPhoto,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAttach,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              cursorColor: AppColors.accent,
              style: AppTypography.body(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.messageTypeHint,
                hintStyle: AppTypography.body(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brPill,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brPill,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brPill,
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.messageSend,
            child: Material(
              color: AppColors.accent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: AppColors.onAccent,
                    size: 20,
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

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.name,
    required this.group,
    required this.online,
    this.imageUrl,
  });

  final String name;
  final bool group;
  final bool online;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceRaised,
            backgroundImage: imageUrl == null
                ? null
                : NetworkImage(resolveAssetUrl(imageUrl!)),
            child: imageUrl != null
                ? null
                : group
                    ? const Icon(
                        Icons.groups_2_outlined,
                        color: AppColors.textMuted,
                      )
                    : Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: AppTypography.display(size: 14),
                      ),
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
              ),
            ),
        ],
      );
}
