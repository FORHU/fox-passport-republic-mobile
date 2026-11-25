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

Map<String, Object?> _event(
  List<Map<String, Object?>> suppliers, {
  String? declinable,
  String? editable,
}) =>
    {
      'success': true,
      'data': {
        'eventId': 'e1',
        'eventName': 'Garden wedding',
        'startAt': '2026-12-05T10:00:00Z',
        'endAt': '2026-12-05T15:00:00Z',
        'eventStatus': 'pending',
        'declinableBookingId': declinable,
        if (editable != null) 'editableBookingId': editable,
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
          {
            ..._supplier(
              'asset',
              'Lights',
              status: 'rejected',
              reason: 'declined',
            ),
            'cause': 'busy',
          },
        ]),
      );

      await show(tester);

      expect(find.text('This event needs a replacement'), findsOneWidget);
      expect(find.text('Declined this event'), findsOneWidget);
      expect(find.text('Blocked a day of this event'), findsOneWidget);
      expect(find.text('No longer available'), findsOneWidget);
      expect(find.text('Busy with another booking'), findsOneWidget);
    });

    testWidgets("shows the Supplier's own reason and note (mobile#513)", (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([
          {
            ..._supplier(
              'venue',
              'Sky Hall',
              status: 'rejected',
              reason: 'declined',
            ),
            'declineReason': 'closed',
            'declineNote': 'Roof repairs that week',
          },
          {
            ..._supplier(
              'asset',
              'Lights',
              status: 'rejected',
              reason: 'declined',
            ),
            'declineReason': 'closed',
          },
        ]),
      );

      await show(tester);

      expect(find.text('Declined: closed that day'), findsOneWidget);
      expect(find.text('Declined: not available that day'), findsOneWidget);
      expect(find.text('“Roof repairs that week”'), findsOneWidget);
      expect(find.byKey(const Key('booked-decline-note')), findsOneWidget);
      expect(find.text('Declined this event'), findsNothing);
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

    group('the host declining', () {
      testWidgets('is not offered once the booking is paid', (tester) async {
        when(() => api.get(ApiEndpoints.bookedEvent('e1')))
            .thenAnswer((_) async => _event([_supplier('asset', 'Lights')]));

        await show(tester);

        expect(find.text("I can't run this event"), findsNothing);
      });

      testWidgets('asks first, then says the host is busy', (tester) async {
        when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
          (_) async => _event([_supplier('asset', 'Lights')], declinable: 'b1'),
        );
        when(
          () => api.post(ApiEndpoints.bookingDecline('b1'), any()),
        ).thenAnswer((_) async => {'success': true});

        await show(tester);
        await tester.tap(find.text("I can't run this event"));
        await tester.pumpAndSettle();
        expect(find.text('Decline this event?'), findsOneWidget);
        verifyNever(() => api.post(ApiEndpoints.bookingDecline('b1'), any()));

        await tester.tap(find.text("I'm busy then"));
        await tester.pumpAndSettle();

        verify(
          () => api.post(ApiEndpoints.bookingDecline('b1'), {'cause': 'busy'}),
        ).called(1);
        expect(
          find.text('You declined. The citizen and the Suppliers were told.'),
          findsOneWidget,
        );
      });

      testWidgets('shows the reason when the API refuses', (tester) async {
        when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
          (_) async => _event([_supplier('asset', 'Lights')], declinable: 'b1'),
        );
        when(
          () => api.post(ApiEndpoints.bookingDecline('b1'), any()),
        ).thenThrow(const ServerException('This booking is already paid.'));

        await show(tester);
        await tester.tap(find.text("I can't run this event"));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Decline this event'));
        await tester.pumpAndSettle();

        expect(find.text('This booking is already paid.'), findsOneWidget);
      });
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

  group('replacing a Supplier', () {
    Map<String, Object?> declined({String? proposal}) => {
          ..._supplier('asset', 'Sound system', reason: 'declined'),
          'pendingProposalId': proposal,
        };

    test('a Supplier reads its line and any proposal waiting on it', () {
      final e = BookedEvent.tryParse(
        _event([declined(proposal: 'p1')])['data'],
      )!;

      expect(e.suppliers.single.transactionId, 't-Sound system');
      expect(e.suppliers.single.pendingProposalId, 'p1');
    });

    test('a candidate reads its price and whether it is a partner', () {
      final c = ReplacementCandidate.tryParse({
        'itemId': 'a2',
        'name': 'Bigger speakers',
        'supplierName': 'Ana Audio',
        'price': '5500',
        'partner': true,
      })!;

      expect(c.price, 5500);
      expect(c.partner, isTrue);
      expect(ReplacementCandidate.tryParse({'name': 'x'}), isNull);
    });

    testWidgets('is not offered once the booking is paid', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1')))
          .thenAnswer((_) async => _event([declined()]));

      await show(tester);

      expect(find.text('Find a replacement'), findsNothing);
    });

    testWidgets('is offered only on the Supplier that needs replacing', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event(
          [declined(), _supplier('service', 'Photographer')],
          declinable: 'b1',
        ),
      );

      await show(tester);

      expect(find.text('Find a replacement'), findsOneWidget);
    });

    testWidgets('lists candidates, asks first, then sends the proposal', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([declined()], declinable: 'b1'),
      );
      when(
        () => api.get(
          ApiEndpoints.eventReplacements('t-Sound system'),
          query: {'kind': 'asset'},
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'itemId': 'a2',
              'name': 'Bigger speakers',
              'supplierName': 'Ana Audio',
              'price': '5500',
              'partner': false,
            },
          ],
        },
      );
      when(
        () => api.post(ApiEndpoints.eventReplace('t-Sound system'), any()),
      ).thenAnswer((_) async => {'success': true});

      await show(tester);
      await tester.tap(find.text('Find a replacement'));
      await tester.pumpAndSettle();

      expect(find.text('Replace Sound system'), findsOneWidget);
      expect(find.text('Ana Audio'), findsOneWidget);

      await tester.tap(find.text('Bigger speakers'));
      await tester.pumpAndSettle();
      expect(find.text('Propose Bigger speakers?'), findsOneWidget);
      verifyNever(
        () => api.post(ApiEndpoints.eventReplace('t-Sound system'), any()),
      );

      await tester.tap(find.text('Propose'));
      await tester.pumpAndSettle();

      verify(
        () => api.post(ApiEndpoints.eventReplace('t-Sound system'), {
          'kind': 'asset',
          'itemId': 'a2',
        }),
      ).called(1);
      expect(find.text('Sent. The citizen will answer.'), findsOneWidget);
    });

    testWidgets('says so when nothing like it is free', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([declined()], declinable: 'b1'),
      );
      when(
        () => api.get(
          ApiEndpoints.eventReplacements('t-Sound system'),
          query: {'kind': 'asset'},
        ),
      ).thenAnswer((_) async => {'success': true, 'data': <Object>[]});

      await show(tester);
      await tester.tap(find.text('Find a replacement'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nothing like it is free on those dates.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a waiting proposal, which can be withdrawn', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([declined(proposal: 'p1')], declinable: 'b1'),
      );
      when(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'withdraw')),
      ).thenAnswer((_) async => {'success': true});

      await show(tester);

      expect(find.text('Find a replacement'), findsNothing);
      expect(
        find.text('Replacement sent, waiting for the citizen'),
        findsOneWidget,
      );

      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();

      verify(
        () => api.post(ApiEndpoints.eventEditProposalAnswer('p1', 'withdraw')),
      ).called(1);
      expect(find.text('Proposal withdrawn.'), findsOneWidget);
    });
  });

  group('the replacement deadline', () {
    Map<String, Object?> declined(String replaceBy) => {
          ..._supplier('asset', 'Sound system', reason: 'declined'),
          'replaceBy': replaceBy,
        };

    test('a Supplier reads by when it must be replaced', () {
      final e = BookedEvent.tryParse(
        _event([declined('2026-11-20T10:00:00Z')])['data'],
      )!;

      expect(
        e.suppliers.single.replaceBy,
        DateTime.utc(2026, 11, 20, 10).toLocal(),
      );
    });

    testWidgets('says by when, before the deadline', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([declined('2099-01-01T12:00:00Z')]),
      );

      await show(tester);

      expect(find.textContaining('Replace by '), findsOneWidget);
      expect(
        find.textContaining('or the citizen can cancel for a full refund'),
        findsOneWidget,
      );
    });

    testWidgets('says a full refund is open, once past it', (tester) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event([declined('2000-01-01T00:00:00Z')]),
      );

      await show(tester);

      expect(
        find.text(
          'Past the deadline. The citizen can cancel for a full refund.',
        ),
        findsOneWidget,
      );
    });
  });

  group('a paid booking (slice 3)', () {
    testWidgets('can still have a Supplier replaced, but not be declined', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.bookedEvent('e1'))).thenAnswer(
        (_) async => _event(
          [_supplier('asset', 'Sound system', reason: 'declined')],
          editable: 'b1',
        ),
      );

      await show(tester);

      expect(find.text('Find a replacement'), findsOneWidget);
      expect(find.text("I can't run this event"), findsNothing);
    });
  });
}
