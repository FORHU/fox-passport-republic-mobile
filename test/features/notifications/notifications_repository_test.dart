import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late NotificationsRepository repository;

  setUp(() {
    api = _MockApiService();
    repository = NotificationsRepository(api);
  });

  test('parses inbox shape returned by the API', () async {
    when(
      () => api.get(
        ApiEndpoints.notifications,
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => {
        'success': true,
        'unreadCount': 1,
        'notifications': [
          {
            'id': 'notification-1',
            'type': 'booking_update',
            'title': 'Booking confirmed',
            'message': 'Your booking is confirmed.',
            'isRead': false,
            'createdAt': '2025-01-02T03:04:05.000Z',
          },
        ],
      },
    );

    final inbox = await repository.load();

    expect(inbox.unreadCount, 1);
    expect(inbox.notifications, hasLength(1));
    expect(inbox.notifications.single.title, 'Booking confirmed');
    expect(inbox.notifications.single.isRead, isFalse);
  });

  test('uses the API read endpoints', () async {
    when(() => api.patch(any())).thenAnswer((_) async => {'success': true});

    await repository.markAsRead('notification-1');
    await repository.markAllAsRead();

    verify(() => api.patch(ApiEndpoints.notificationRead('notification-1')))
        .called(1);
    verify(() => api.patch(ApiEndpoints.notificationsReadAll)).called(1);
  });
}
