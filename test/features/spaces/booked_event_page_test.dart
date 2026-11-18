import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/notifications/domain/notification_route.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/booked_event_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, Object?> _supplier(
  String kind,
  String item, {
  String supplier = 'Maria Provider',
  String status = 'approved',
  String? reason,
}) =>
    {
      'kind': kind,
      'transactionId': 't-$item',
      'supplierName': supplier,
      'itemName': item,
      'status': status,
      'reason': reason,
    };

Map<String, Object?> _event(List<Map<String, Object?>> suppliers) => {
      'success': true,
      'data': {
        'eventId': 'e1',
        'eventName': 'Garden wedding',
        'startAt': '2026-12-05T10:00:00Z',
        'endAt': '2026-12-05T15:00:00Z',
        'eventStatus': 'pending',
        'suppliers': suppliers,
      },
    };

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  Future<void> show(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          spacesRepositoryProvider.overrideWithValue(
            SpacesRepository(api, 'u1'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookedEventPage(eventId: 'e1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('parsing', () {
    test('an event reads its Suppliers and which ones need replacing', () {
      final e = BookedEvent.tryParse(
        _event([
          _supplier('venue', 'Sky Hall', reason: 'date_blocked'),
          _supplier('asset', 'Sound system'),
          _supplier('service', 'Photographer', status: 'rejected'),
        ])['data'],
      )!;

      expect(e.eventName, 'Garden wedding');
      expect(e.suppliers.map((s) => s.kind), [
        RequestKind.venue,
        RequestKind.asset,
        RequestKind.service,
      ]);
      expect(e.suppliers[0].problem, AttentionReason.dateBlocked);
      expect(e.suppliers[1].problem, isNull);
      expect(e.suppliers[2].status, RequestStatus.rejected);
      expect(e.needsReplacement, isTrue);
    });

    test('an event with no problem does not need a replacement', () {
      final e = BookedEvent.tryParse(
        _event([_supplier('asset', 'Sound system')])['data'],
      )!;

      expect(e.needsReplacement, isFalse);
    });

    test('an answer with no event in it is not an event', () {
      expect(BookedEvent.tryParse(null), isNull);
      expect(BookedEvent.tryParse({'suppliers': <Object>[]}), isNull);
    });
  });

  group('the booked event page', () {
    testWidgets('shows the event, its date and every Supplier', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([
          _supplier('venue', 'Sky Hall', supplier: 'Mayor Cruz'),
          _supplier('asset', 'Sound system'),
        ]),
      );

      await show(tester);

      expect(find.text('Garden wedding'), findsOneWidget);
      expect(find.textContaining('Dec 5'), findsOneWidget);
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Mayor Cruz'), findsOneWidget);
      expect(find.text('Sound system'), findsOneWidget);
      expect(find.text('Maria Provider'), findsOneWidget);
      expect(find.text('This event needs a replacement'), findsNothing);
    });

    testWidgets('marks a Supplier that needs replacing and says why', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([
          _supplier(
            'asset',
            'Sound system',
            status: 'rejected',
            reason: 'declined',
          ),
          _supplier('venue', 'Sky Hall', reason: 'date_blocked'),
          _supplier(
            'service',
            'Photographer',
            reason: 'unavailable',
          ),
        ]),
      );

      await show(tester);

      expect(find.text('This event needs a replacement'), findsOneWidget);
      expect(find.text('Declined this event'), findsOneWidget);
      expect(find.text('Blocked a day of this event'), findsOneWidget);
      expect(find.text('No longer available'), findsOneWidget);
    });

    testWidgets('says so when no Supplier is booked yet', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1')))
          .thenAnswer((_) async => _event([]));

      await show(tester);

      expect(
        find.text('No Suppliers are booked for this event yet.'),
        findsOneWidget,
      );
    });

    testWidgets('offers a retry when the event cannot be read', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1')))
          .thenThrow(const NetworkException());

      await show(tester);

      expect(find.text('We could not find that event.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('opening it', () {
    test('the route is where the notification and the Overview point', () {
      expect(RouteNames.bookedEvent('e1'), '/space/event/booked/e1');
      expect(RouteNames.bookedEvent('a b'), '/space/event/booked/a%20b');
    });

    test('a notification link for an event opens it', () {
      expect(
        notificationRoute('/creator-dashboard/events?eventId=e1'),
        '/space/event/booked/e1',
      );
    });

    test('the plain events link, or one with no event, has no screen here', () {
      expect(notificationRoute('/creator-dashboard/events'), isNull);
      expect(notificationRoute('/creator-dashboard/events?eventId='), isNull);
      expect(
        notificationRoute('/creator-dashboard/earnings?eventId=e1'),
        isNull,
      );
      expect(notificationRoute('/creator-dashboard'), isNull);
    });
  });
}
