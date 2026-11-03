import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/features/notifications/domain/entities/user_notification.dart';
import 'package:flutter_template/features/notifications/domain/notification_route.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inbox = ref.watch(notificationInboxProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          inbox.maybeWhen(
            data: (value) => value.unreadCount == 0
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _markAllRead(context, ref),
                    child: Text(l10n.notificationsMarkAllRead),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: inbox.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => _ErrorState(
          message: l10n.apiLoadFailed,
          retryLabel: l10n.retry,
          onRetry: () => ref.invalidate(notificationInboxProvider),
        ),
        data: (value) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => _refresh(ref),
          child: value.notifications.isEmpty
              // Scrollable even when empty, so it can still be pulled down.
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      child: Center(
                        child: Text(
                          l10n.notificationsEmpty,
                          style: AppTypography.body(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: value.notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = value.notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => _open(context, ref, notification),
                    );
                  },
                ),
        ),
      ),
    );
  }

  /// Pull to refresh holds the spinner until the new list has arrived.
  Future<void> _refresh(WidgetRef ref) async {
    try {
      ref.invalidate(notificationInboxProvider);
      await ref.read(notificationInboxProvider.future);
    } on Object {
      // The page shows its own error state; nothing more to do here.
    }
  }

  /// Marks the notification read, then opens what it is about when this app
  /// has a screen for it.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    UserNotification notification,
  ) async {
    final route = notificationRoute(notification.link);
    if (!notification.isRead) {
      final done = await _guard(
        context,
        () => ref
            .read(notificationsRepositoryProvider)
            .markAsRead(notification.id),
      );
      ref.invalidate(notificationInboxProvider);
      // A failed mark-as-read must not trap the user on this page.
      if (!done) return;
    }
    if (!context.mounted) return;
    // A spot opened on a full event: open the event so it can be booked.
    final templateId = notification.eventTemplateId;
    if (route == null && templateId != null) {
      unawaited(
        context.push(
          RouteNames.eventDetail,
          extra: CatalogItem(
            id: templateId,
            kind: CatalogKind.events,
            title: notification.title,
          ),
        ),
      );
      return;
    }
    if (route == null) return;
    // A chat is pushed over the tabs; any other target is a tab to switch to.
    if (route.startsWith('${RouteNames.messages}/') ||
        route.startsWith('${RouteNames.republic}/post/')) {
      unawaited(context.push(route));
    } else {
      context.go(route);
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    await _guard(
      context,
      () => ref.read(notificationsRepositoryProvider).markAllAsRead(),
    );
    ref.invalidate(notificationInboxProvider);
  }

  /// Runs [action]; a failure of any kind is shown, never thrown.
  Future<bool> _guard(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final failed = context.l10n.notificationsUpdateFailed;
    try {
      await action();
      return true;
    } on Object catch (error) {
      if (context.mounted) {
        showTopToast(context, error is AppException ? error.message : failed);
      }
      return false;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final UserNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notification.isRead
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_active_outlined,
                color: notification.isRead
                    ? AppColors.textMuted
                    : AppColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTypography.display(),
                    ),
                    if (notification.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTypography.body(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.yMMMd(locale).add_jm().format(
                            notification.createdAt,
                          ),
                      style: AppTypography.label(),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 6),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTypography.body(),
            ),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      );
}
