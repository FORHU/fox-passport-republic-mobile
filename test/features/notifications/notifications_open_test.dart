import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/features/notifications/domain/entities/user_notification.dart';
import 'package:flutter_template/features/notifications/domain/notification_route.dart';
import 'package:flutter_template/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

UserNotification _note(
  String id, {
  String? link,
  bool read = false,
  String title = 'Something happened',
}) =>
    UserNotification(
      id: id,
      type: 'booking_update',
      title: title,
      message: '',
      createdAt: DateTime(2026, 10, 19, 9),
      isRead: read,
      link: link,
    );

/// Serves a fixed list and records what was marked read.
class _FakeNotifications extends NotificationsRepository {
  _FakeNotifications(this.items, {this.failMarkRead = false})
      : super(_MockApi());

  final List<UserNotification> items;
  final bool failMarkRead;
  final marked = <String>[];
  int loads = 0;

  @override
  Future<NotificationInbox> load() async {
    loads++;
    return NotificationInbox(
      notifications: items,
      unreadCount: items.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    if (failMarkRead) throw Exception('offline');
    marked.add(id);
  }
}

Future<void> _open(WidgetTester tester, _FakeNotifications repo) async {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(path: '/tickets', builder: (_, __) => const Text('TICKETS')),
      GoRoute(path: '/messages', builder: (_, __) => const Text('MESSAGES')),
      GoRoute(
        path: '/messages/:id',
        builder: (_, s) => Text('CHAT ${s.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('notificationRoute', () {
    test('a booking goes to Tickets', () {
      expect(notificationRoute('/booking/b1'), '/tickets');
      expect(notificationRoute('/bookings/b1'), '/tickets');
      expect(notificationRoute('/booking/fulfillment/asset/b1'), '/tickets');
    });

    test('a conversation opens that chat, other message links the list', () {
      expect(
        notificationRoute('/messages?conversationId=c9'),
        '/messages/c9',
      );
      expect(notificationRoute('/messages?userId=u2'), '/messages');
      expect(notificationRoute('/messages'), '/messages');
    });

    test('the passport and the calendar open their tabs', () {
      expect(notificationRoute('/user/passport'), '/passport');
      expect(notificationRoute('/calendar'), '/calendar');
    });

    test('links with no screen in the app map to nothing', () {
      expect(notificationRoute(null), isNull);
      expect(notificationRoute(''), isNull);
      expect(notificationRoute('/user/u123'), isNull);
      expect(notificationRoute('/host/bookings/b1'), isNull);
      expect(notificationRoute('/invoices/i1'), isNull);
      expect(notificationRoute('/event/e1'), isNull);
    });
  });

  group('UserNotification', () {
    Map<String, dynamic> json(Object? metadata) => {
          'id': 'n1',
          'type': 't',
          'title': 'T',
          'message': 'M',
          'isRead': false,
          'createdAt': '2026-10-19T09:00:00.000Z',
          'metadata': metadata,
        };

    test('reads the link from metadata', () {
      final n = UserNotification.fromJson(json({'link': '/booking/b1'}));
      expect(n.link, '/booking/b1');
    });

    test('has no link without metadata or with a blank one', () {
      expect(UserNotification.fromJson(json(null)).link, isNull);
      expect(UserNotification.fromJson(json({'link': ''})).link, isNull);
      expect(UserNotification.fromJson(json({'link': 7})).link, isNull);
    });
  });

  group('NotificationsPage', () {
    testWidgets('tapping an unread chat notification marks it and opens it', (
      tester,
    ) async {
      final repo = _FakeNotifications([
        _note('n1', link: '/messages?conversationId=c9'),
      ]);
      await _open(tester, repo);

      await tester.tap(find.text('Something happened'));
      await tester.pumpAndSettle();

      expect(repo.marked, ['n1']);
      expect(find.text('CHAT c9'), findsOneWidget);
    });

    testWidgets('a booking notification opens Tickets, even when read', (
      tester,
    ) async {
      final repo = _FakeNotifications([
        _note('n1', link: '/booking/b1', read: true),
      ]);
      await _open(tester, repo);

      await tester.tap(find.text('Something happened'));
      await tester.pumpAndSettle();

      expect(repo.marked, isEmpty);
      expect(find.text('TICKETS'), findsOneWidget);
    });

    testWidgets('one with no screen is only marked read', (tester) async {
      final repo = _FakeNotifications([_note('n1', link: '/user/u123')]);
      await _open(tester, repo);

      await tester.tap(find.text('Something happened'));
      await tester.pumpAndSettle();

      expect(repo.marked, ['n1']);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('a failed mark-as-read is shown and does not navigate', (
      tester,
    ) async {
      final repo = _FakeNotifications(
        [_note('n1', link: '/booking/b1')],
        failMarkRead: true,
      );
      await _open(tester, repo);

      await tester.tap(find.text('Something happened'));
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't update your notifications. Try again."),
        findsOneWidget,
      );
      expect(find.text('TICKETS'), findsNothing);
    });

    testWidgets('an empty inbox can still be pulled to refresh', (
      tester,
    ) async {
      final repo = _FakeNotifications([]);
      await _open(tester, repo);
      expect(find.text("You're all caught up."), findsOneWidget);
      final before = repo.loads;

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repo.loads, greaterThan(before));
    });
  });
}
