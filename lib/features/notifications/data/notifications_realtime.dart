import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';

/// Reloads the notification inbox (and so the bell's badge) when the server
/// pushes a new notification. Watch it once, high in the tree.
final notificationsRealtimeProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  if (service == null) return;

  final subscription = service.events.listen((event) {
    if (event.name == RealtimeEvents.newNotification) {
      ref.invalidate(notificationInboxProvider);
    }
  });
  ref.onDispose(subscription.cancel);
});
