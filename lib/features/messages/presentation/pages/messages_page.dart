import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/messages/data/messages_realtime.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/messages/presentation/widgets/new_chat_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _ConversationFilter { all, bookings, groups, requests }

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  _ConversationFilter _filter = _ConversationFilter.all;
  final _searchController = TextEditingController();
  String _query = '';
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conversations = ref.watch(conversationsProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _searching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) =>
                                setState(() => _query = value.trim()),
                            style: AppTypography.body(),
                            decoration: InputDecoration(
                              hintText: l10n.messageSearchHint,
                              hintStyle: AppTypography.body(
                                color: AppColors.textMuted,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          )
                        : Text(
                            l10n.messages,
                            style: AppTypography.display(size: 22),
                          ),
                  ),
                  IconButton(
                    tooltip: l10n.messageSearchHint,
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) {
                        _searchController.clear();
                        _query = '';
                      }
                    }),
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.messageNew,
                    onPressed: _newChat,
                    icon: const Icon(
                      Icons.edit_square,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final filter in _ConversationFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        selected: _filter == filter,
                        label: _filterLabel(l10n, filter),
                        count: filter == _ConversationFilter.requests
                            ? conversations.asData?.value
                                    .where((item) => item.isIncomingRequest)
                                    .length ??
                                0
                            : null,
                        onTap: () => setState(() => _filter = filter),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: conversations.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => _LoadError(
                  message: l10n.messagesLoadFailed,
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
                data: (items) {
                  final visible = items.where(_matches).toList(growable: false);
                  if (visible.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          items.isEmpty
                              ? l10n.messagesEmpty
                              : l10n.messageSearchHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () async =>
                        ref.invalidate(conversationsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppColors.border,
                        height: 1,
                        indent: 58,
                      ),
                      itemBuilder: (context, index) => _ConversationTile(
                        conversation: visible[index],
                        onTap: () => context.push(
                          RouteNames.chat(visible[index].id),
                          extra: visible[index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _newChat() async {
    final id = await showNewChatSheet(context);
    if (id != null && mounted) unawaited(context.push(RouteNames.chat(id)));
  }

  bool _matches(Conversation conversation) {
    final filterMatches = switch (_filter) {
      _ConversationFilter.all => true,
      _ConversationFilter.bookings =>
        conversation.contextLabel != null || conversation.isInbox,
      _ConversationFilter.groups => conversation.isGroup,
      _ConversationFilter.requests => conversation.hasPendingRequest,
    };
    if (!filterMatches) return false;
    if (_query.isEmpty) return true;
    return conversation.title.toLowerCase().contains(_query.toLowerCase()) ||
        (conversation.contextLabel?.toLowerCase().contains(
                  _query.toLowerCase(),
                ) ??
            false);
  }

  String _filterLabel(AppLocalizations l10n, _ConversationFilter filter) =>
      switch (filter) {
        _ConversationFilter.all => l10n.messageFilterAll,
        _ConversationFilter.bookings => l10n.messageFilterBookings,
        _ConversationFilter.groups => l10n.messageFilterGroups,
        _ConversationFilter.requests => l10n.messageFilterRequests,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.count,
  });

  final bool selected;
  final String label;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightSurface : AppColors.canvas,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.lightSurface : AppColors.borderStrong,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.body(
                  size: 12,
                  color: selected ? AppColors.canvas : AppColors.textPrimary,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: AppTypography.display(
                    size: 12,
                    color: selected ? AppColors.canvas : AppColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final typing = ref.watch(typingProvider).contains(conversation.id);
    final contextLabel = conversation.isInbox
        ? conversation.inboxType == 'event'
            ? l10n.messageEventInbox
            : l10n.messageVenueInbox
        : conversation.contextLabel;
    final subtitle = conversation.lastMessage == null
        ? ''
        : '${conversation.lastMessageIsMine ? l10n.messageYou : ''}'
            '${conversation.lastMessage}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _Avatar(
              name: conversation.title,
              square: conversation.isInbox,
              group: conversation.isGroup,
              online: conversation.otherUserOnline,
              imageUrl: conversation.avatarUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (conversation.isPinned) ...[
                              const Icon(
                                Icons.push_pin_rounded,
                                size: 13,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 3),
                            ],
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
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(
                          _compactTime(context, conversation.lastMessageAt!),
                          style: AppTypography.label(),
                        ),
                    ],
                  ),
                  if (contextLabel != null && contextLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          typing
                              ? l10n.messageTyping
                              : conversation.hasPendingRequest &&
                                      subtitle.isEmpty
                                  ? l10n.messageRequestPending
                                  : subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            size: 12,
                            color: typing
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (conversation.isMuted)
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            textAlign: TextAlign.center,
                            style: AppTypography.display(
                              size: 11,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _compactTime(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final elapsed = DateTime.now().difference(date);
    if (elapsed.inMinutes < 1) return context.l10n.messageNow;
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m';
    if (elapsed.inDays < 1) return '${elapsed.inHours}h';
    if (elapsed.inDays < 7) return DateFormat.E(locale).format(date);
    return DateFormat.MMMd(locale).format(date);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.square,
    required this.group,
    required this.online,
    this.imageUrl,
  });

  final String name;
  final bool square;
  final bool group;
  final bool online;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          // Clips the picture to the circle or rounded square.
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border.all(color: AppColors.border),
            borderRadius: square ? AppRadius.brSm : null,
            shape: square ? BoxShape.rectangle : BoxShape.circle,
          ),
          child: imageUrl != null
              ? NetworkImageBox(url: imageUrl!, width: 44, height: 44)
              : group
                  ? const Icon(
                      Icons.groups_2_outlined,
                      color: AppColors.textMuted,
                    )
                  : Text(
                      initials,
                      style: AppTypography.display(
                        color: AppColors.textSecondary,
                      ),
                    ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
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
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTypography.body(color: AppColors.textMuted)),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
