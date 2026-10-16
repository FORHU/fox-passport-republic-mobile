import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/notifications/domain/entities/user_notification.dart';

class NotificationInbox {
  const NotificationInbox({
    required this.notifications,
    required this.unreadCount,
  });

  final List<UserNotification> notifications;
  final int unreadCount;
}

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiService _api;

  Future<NotificationInbox> load() async {
    final body = await _api.get(
      ApiEndpoints.notifications,
      query: const {'limit': 100},
    );
    if (body is! Map || body['notifications'] is! List) {
      throw const FormatException('Notifications response is malformed');
    }
    final rows = body['notifications'] as List;
    final unreadCount = body['unreadCount'];
    return NotificationInbox(
      notifications: [
        for (final row in rows)
          if (row is Map)
            UserNotification.fromJson(row.cast<String, dynamic>()),
      ],
      unreadCount: unreadCount is num ? unreadCount.toInt() : 0,
    );
  }

  Future<void> markAsRead(String id) async {
    await _api.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllAsRead() async {
    await _api.patch(ApiEndpoints.notificationsReadAll);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiServiceProvider)),
);

final FutureProvider<NotificationInbox> notificationInboxProvider =
    FutureProvider.autoDispose<NotificationInbox>(
  (ref) => ref.watch(notificationsRepositoryProvider).load(),
);
