import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/features/notifications/domain/entities/user_notification.dart';
import 'package:flutter_template/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _json(String type, Map<String, dynamic>? metadata) => {
      'id': 'n1',
      'type': type,
      'title': 'A spot opened up!',
      'message': 'A spot just opened for "Garden Birthday".',
      'createdAt': '2026-10-26T09:00:00.000Z',
      'isRead': false,
      'metadata': metadata,
    };

class _Fake extends NotificationsRepository {
  _Fake(this.items) : super(_MockApi());

  final List<UserNotification> items;
  final marked = <String>[];

  @override
  Future<NotificationInbox> load() async =>
      NotificationInbox(notifications: items, unreadCount: items.length);

  @override
  Future<void> markAsRead(String id) async => marked.add(id);
}

void main() {
  group('reading a notification', () {
    test('a waitlist spot carries the event it is about', () {
      final n = UserNotification.fromJson(
        _json('waitlist_spot_available', {'templateId': 't1'}),
      );

      expect(n.eventTemplateId, 't1');
      expect(n.link, isNull);
    });

    test('no other kind does, whatever its metadata says', () {
      expect(
        UserNotification.fromJson(
          _json('booking_update', {'templateId': 't1'}),
        ).eventTemplateId,
        isNull,
      );
      expect(
        UserNotification.fromJson(_json('waitlist_spot_available', null))
            .eventTemplateId,
        isNull,
      );
      expect(
        UserNotification.fromJson(
          _json('waitlist_spot_available', {'templateId': ''}),
        ).eventTemplateId,
        isNull,
      );
    });
  });

  testWidgets('tapping a spot-opened notification opens that event', (
    tester,
  ) async {
    final repo = _Fake([
      UserNotification.fromJson(
        _json('waitlist_spot_available', {'templateId': 't1'}),
      ),
    ]);
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage(),
        ),
        GoRoute(
          path: RouteNames.eventDetail,
          builder: (_, state) {
            final item = state.extra! as CatalogItem;
            return Text('EVENT ${item.id} ${item.kind.name}');
          },
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

    await tester.tap(find.text('A spot opened up!'));
    await tester.pumpAndSettle();

    expect(find.text('EVENT t1 events'), findsOneWidget);
    expect(repo.marked, ['n1']);
  });
}
