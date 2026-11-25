import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/check_in_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/event_overview_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/events_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/booking_decline_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ada',
          roleType: ['venueFoxer', 'eventFoxer'],
        ),
      );
}

Map<String, Object?> _request(
  String id, {
  String status = 'pending_provider_confirmation',
}) =>
    {
      'id': id,
      'status': status,
      'agreedPrice': 25000,
      'event': {
        'name': 'Ada Birthday',
        'startAt': '2099-12-25T10:00:00.000Z',
        'client': {'name': 'Ada'},
      },
      'venue': {'name': 'Sky Hall'},
    };

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    // The switcher button in each page's top bar reads the saved space.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_Session.new),
          spacesRepositoryProvider.overrideWithValue(
            SpacesRepository(api, 'u1'),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void requestsReturn(List<Map<String, Object?>> venues) {
    when(() => api.get(ApiEndpoints.providerRequests)).thenAnswer(
      (_) async => {'venues': venues, 'assets': <Object>[]},
    );
  }

  group('requests', () {
    testWidgets('shows the request, who asked and the price', (tester) async {
      requestsReturn([_request('r1')]);

      await pump(tester, const VenueRequestsPage());

      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.textContaining('Ada Birthday'), findsOneWidget);
      expect(find.text('From Ada'), findsOneWidget);
      expect(find.text('Needs your reply'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('an answered request has no buttons, only its outcome', (
      tester,
    ) async {
      requestsReturn([_request('r1', status: 'approved')]);

      await pump(tester, const VenueRequestsPage());

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('accepting confirms it and says so', (tester) async {
      requestsReturn([_request('r1')]);
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      await pump(tester, const VenueRequestsPage());

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      verify(
        () => api.patch(
          ApiEndpoints.requestReview('r1'),
          {'type': 'venue', 'action': 'confirm'},
        ),
      ).called(1);
      expect(find.text('Request accepted.'), findsOneWidget);
    });

    testWidgets('declining asks first, then rejects it', (tester) async {
      requestsReturn([_request('r1')]);
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      await pump(tester, const VenueRequestsPage());

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      expect(find.text("Why can't Sky Hall host this?"), findsOneWidget);
      await tester.tap(find.text("Doesn't suit this event"));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BookingDeclineSheet),
          matching: find.text('Decline'),
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => api.patch(
          ApiEndpoints.requestReview('r1'),
          {'type': 'venue', 'action': 'reject', 'reason': 'not_suitable'},
        ),
      ).called(1);
      expect(find.text('Request declined.'), findsOneWidget);
    });

    testWidgets('backing out of the decline question changes nothing', (
      tester,
    ) async {
      requestsReturn([_request('r1')]);
      await pump(tester, const VenueRequestsPage());

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      verifyNever(() => api.patch(any(), any()));
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('says so when the answer did not go through', (tester) async {
      requestsReturn([_request('r1')]);
      when(() => api.patch(any(), any())).thenThrow(
        const ServerException('Already answered'),
      );
      await pump(tester, const VenueRequestsPage());

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't update that request. Try again."),
        findsOneWidget,
      );
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('has a friendly empty state', (tester) async {
      requestsReturn([]);

      await pump(tester, const VenueRequestsPage());

      expect(find.textContaining('No requests yet'), findsOneWidget);
    });

    testWidgets('offers a retry when it will not load', (tester) async {
      when(() => api.get(ApiEndpoints.providerRequests))
          .thenThrow(Exception('offline'));

      await pump(tester, const VenueRequestsPage());

      expect(find.text("We couldn't load this right now."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('the Event home', () {
    Map<String, Object?> event(
      String id,
      String name,
      String status, {
      String? city,
    }) =>
        {
          'id': id,
          'name': name,
          'status': status,
          if (city != null) 'targetCity': city,
        };

    Map<String, Object?> invite(String id) => {
          'id': id,
          'status': 'pending',
          'initiatedBy': 'venueFoxer',
          'venue': {'id': 'v1', 'name': 'Sky Hall'},
          'eventFoxer': {'id': 'e1', 'name': 'Ada'},
        };

    void api_({
      List<Map<String, Object?>> events = const [],
      List<Map<String, Object?>> invites = const [],
    }) {
      when(() => api.get(ApiEndpoints.events, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {'templates': events, 'total': events.length},
      );
      when(() => api.get(ApiEndpoints.venueAffiliationsMine)).thenAnswer(
        (_) async => {
          'data': {'asVenueMayor': <Object>[], 'asEventFoxer': invites},
        },
      );
      // Nothing earned yet, which is what makes a Foxer new.
      when(
        () => api.get(ApiEndpoints.payoutsMe, query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'data': <Object>[],
          'totals': {'pending': 0, 'paid': 0},
        },
      );
    }

    testWidgets('a new Event Foxer is greeted and shown their first steps', (
      tester,
    ) async {
      api_();
      // No payout account yet.
      when(() => api.get(ApiEndpoints.stripeStatus))
          .thenAnswer((_) async => {'data': <String, Object>{}});
      await pump(tester, const EventOverviewPage());

      expect(find.text('Event Foxer'), findsNothing);
      expect(find.text('Getting started'), findsOneWidget);
      expect(find.text('0 of 3 steps done'), findsOneWidget);
      expect(find.text('Get approved to host at a venue'), findsOneWidget);
      expect(find.text('Build your first event'), findsOneWidget);
      expect(find.text('Connect your payout account'), findsOneWidget);
    });

    testWidgets('first steps tick off from the events and payouts', (
      tester,
    ) async {
      api_(events: [event('e1', 'Bonfire Night', 'pending')]);
      when(() => api.get(ApiEndpoints.stripeStatus)).thenAnswer(
        (_) async => {
          'data': {
            'hasStripeAccount': true,
            'stripeOnboardingComplete': true,
          },
        },
      );
      await pump(tester, const EventOverviewPage());

      // An event and payouts are done; no venue has approved them yet.
      expect(find.text('2 of 3 steps done'), findsOneWidget);
    });

    testWidgets('lists your events with their town and status', (
      tester,
    ) async {
      api_(
        events: [
          event('e1', 'Bonfire Night', 'published', city: 'Baguio'),
          event('e2', 'Garden Party', 'pending'),
        ],
      );
      await pump(tester, const EventsPage());

      expect(find.text('Bonfire Night'), findsOneWidget);
      expect(find.text('Baguio'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      // The first steps sit above the events, so the second one is below.
      await tester.scrollUntilVisible(
        find.text('Garden Party'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Garden Party'), findsOneWidget);
      expect(find.text('2 events'), findsOneWidget);
    });

    testWidgets('New event floats at the bottom, with no Calendar button', (
      tester,
    ) async {
      api_(events: [event('e1', 'Bonfire Night', 'published')]);
      await pump(tester, const EventOverviewPage());

      expect(
        find.widgetWithText(FloatingActionButton, 'New event'),
        findsOneWidget,
      );
      // The calendar is a tab, not a button here too.
      expect(find.text('Calendar'), findsNothing);
    });

    testWidgets('shows events live and in review, and My events', (
      tester,
    ) async {
      api_(
        events: [
          event('e1', 'Live One', 'published', city: 'Baguio'),
          event('e2', 'Waiting One', 'pending'),
          event('e3', 'Draft One', 'draft'),
        ],
      );
      await pump(tester, const EventOverviewPage());
      // The live count, in the numbers above My events.
      await tester.scrollUntilVisible(
        find.text('1 of 3'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 of 3'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Waiting One'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Live One'), findsOneWidget);
      expect(find.text('Waiting One'), findsOneWidget);
      // Two at most.
      expect(find.text('Draft One'), findsNothing);
    });

    // A draft package with one line per Supplier answer (mobile#509).
    Map<String, Object?> package(
      String id,
      String name,
      List<(String, String)> lines,
    ) =>
        {
          ...event(id, name, 'draft'),
          'templateVenues': <Object>[],
          'templateAssets': [
            for (final (item, status) in lines)
              {
                'matched': true,
                'matchRequestStatus': status,
                'asset': {'id': item, 'name': item, 'ownerId': 'o-$item'},
              },
          ],
          'templateServices': <Object>[],
        };

    testWidgets('Home lists packages waiting on someone, swaps first', (
      tester,
    ) async {
      api_(
        events: [
          package('p1', 'Beach Debut', [('Speakers', 'pending')]),
          package('p2', 'Garden Wedding', [('Photos', 'declined')]),
          package('p3', 'Corporate Gala', [('Stage', 'accepted')]),
          event('e4', 'Empty Draft', 'draft'),
        ],
      );
      await pump(tester, const EventOverviewPage());

      final swap = find.text('Garden Wedding: replace Photos');
      final ready = find.text('Corporate Gala is ready to send for review');
      final waiting = find.text('Beach Debut: waiting for Speakers');
      expect(swap, findsOneWidget);
      expect(ready, findsOneWidget);
      expect(waiting, findsOneWidget);
      expect(
        tester.getTopLeft(swap).dy,
        lessThan(tester.getTopLeft(ready).dy),
      );
      expect(
        tester.getTopLeft(ready).dy,
        lessThan(tester.getTopLeft(waiting).dy),
      );
      // Only the draft not listed above is counted as a draft.
      expect(find.text('1 draft to finish'), findsOneWidget);
    });

    testWidgets('the Events tab says where each package stands', (
      tester,
    ) async {
      api_(
        events: [
          package('p1', 'Beach Debut', [
            ('Speakers', 'accepted'),
            ('Photos', 'declined'),
            ('Lights', 'pending'),
          ]),
        ],
      );
      await pump(tester, const EventsPage());

      expect(
        find.text('1 of 3 Suppliers agreed · 1 to replace · 1 waiting'),
        findsOneWidget,
      );
    });

    testWidgets('shows the earnings card with its total', (tester) async {
      api_(events: [event('e1', 'Bonfire Night', 'published')]);
      await pump(tester, const EventOverviewPage());
      await tester.scrollUntilVisible(
        find.text('Total earnings'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('chart here'), findsOneWidget);
    });

    testWidgets('says when all is clear', (tester) async {
      api_(events: [event('e1', 'Bonfire Night', 'published')]);
      await pump(tester, const EventOverviewPage());

      expect(find.text("You're all caught up."), findsOneWidget);
    });

    testWidgets('lists venue invitations waiting for an answer', (
      tester,
    ) async {
      api_(
        events: [event('e1', 'Bonfire Night', 'published')],
        invites: [invite('a'), invite('b')],
      );
      await pump(tester, const EventOverviewPage());

      expect(find.text('2 venue invitations are waiting'), findsOneWidget);
      expect(find.text("You're all caught up."), findsNothing);
    });

    testWidgets('says how many events are in review, declined or drafts', (
      tester,
    ) async {
      api_(
        events: [
          event('e1', 'Live One', 'published'),
          event('e2', 'Waiting One', 'pending'),
          event('e3', 'Declined One', 'rejected'),
          event('e4', 'Draft One', 'draft'),
        ],
      );
      await pump(tester, const EventOverviewPage());

      expect(find.text('1 event is in review'), findsOneWidget);
      expect(find.text('1 event was declined'), findsOneWidget);
      expect(find.text('1 draft to finish'), findsOneWidget);
    });

    testWidgets('opens on one status group when asked to', (tester) async {
      api_(
        events: [
          event('e1', 'Live One', 'published'),
          event('e2', 'Draft One', 'draft'),
        ],
      );
      await pump(tester, const EventsPage(initialGroup: 'draft'));

      expect(find.text('Draft One'), findsOneWidget);
      expect(find.text('Live One'), findsNothing);
      expect(find.text('1 of 2 events'), findsOneWidget);
    });

    testWidgets('filters by status and searches by name', (tester) async {
      api_(
        events: [
          event('e1', 'Bonfire Night', 'published', city: 'Baguio'),
          event('e2', 'Garden Party', 'published', city: 'Sydney'),
          event('e3', 'Old Draft', 'draft'),
        ],
      );
      await pump(tester, const EventsPage());

      expect(find.text('Live 2'), findsOneWidget);
      await tester.tap(find.text('Live 2'));
      await tester.pumpAndSettle();
      expect(find.text('Old Draft'), findsNothing);

      await tester.enterText(find.byType(TextField), 'sydney');
      await tester.pumpAndSettle();
      expect(find.text('Garden Party'), findsOneWidget);
      expect(find.text('Bonfire Night'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No events match.'), findsOneWidget);
    });

    testWidgets('says what to do when there is nothing listed yet', (
      tester,
    ) async {
      api_();
      await pump(tester, const EventsPage());

      expect(find.textContaining("haven't created an event"), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('New event is a filled button with a plus, not a list row', (
      tester,
    ) async {
      api_();
      await pump(tester, const EventsPage());

      final button = find.widgetWithText(FilledButton, 'New event');
      expect(button, findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.add_rounded)),
        findsOneWidget,
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    });

    testWidgets('says so when the events cannot be loaded', (tester) async {
      when(() => api.get(ApiEndpoints.events, query: any(named: 'query')))
          .thenThrow(Exception('down'));
      await pump(tester, const EventsPage());

      expect(find.text("We couldn't load this right now."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('booked events that lost a Supplier', () {
    Map<String, Object?> needing(
      String id,
      String name,
      List<Map<String, Object?>> issues,
    ) =>
        {
          'eventId': id,
          'eventName': name,
          'startAt': '2026-12-05T10:00:00Z',
          'issues': issues,
        };

    Map<String, Object?> issue(
      String reason, {
      String kind = 'asset',
      String supplier = 'Maria Provider',
      String item = 'Sound system',
    }) =>
        {
          'kind': kind,
          'transactionId': 't-$reason',
          'supplierName': supplier,
          'itemName': item,
          'reason': reason,
        };

    void stubHome(List<Map<String, Object?>> needs) {
      when(() => api.get(ApiEndpoints.events, query: any(named: 'query')))
          .thenAnswer((_) async => {'templates': <Object>[], 'total': 0});
      when(() => api.get(ApiEndpoints.venueAffiliationsMine)).thenAnswer(
        (_) async => {
          'data': {'asVenueMayor': <Object>[], 'asEventFoxer': <Object>[]},
        },
      );
      when(
        () => api.get(ApiEndpoints.payoutsMe, query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'data': <Object>[],
          'totals': {'pending': 0, 'paid': 0},
        },
      );
      when(() => api.get(ApiEndpoints.eventsNeedingAttention))
          .thenAnswer((_) async => {'success': true, 'data': needs});
    }

    test('an event reads its issues and ignores one with none', () {
      final e = EventNeedingAttention.tryParse(
        needing('e1', 'Garden wedding', [
          issue('declined'),
          issue('date_blocked', kind: 'venue', supplier: 'Mayor Cruz'),
          issue('anything_else'),
        ]),
      )!;

      expect(e.eventName, 'Garden wedding');
      expect(e.issues.map((i) => i.reason), [
        AttentionReason.declined,
        AttentionReason.dateBlocked,
        AttentionReason.unavailable,
      ]);
      expect(e.issues[1].kind, RequestKind.venue);
      expect(EventNeedingAttention.tryParse(needing('e2', 'x', [])), isNull);
      expect(EventNeedingAttention.tryParse('nonsense'), isNull);
    });

    testWidgets('names the Supplier and the event for each way it can happen', (
      tester,
    ) async {
      stubHome([
        needing('e1', 'Garden wedding', [issue('declined')]),
        needing('e2', 'Reunion', [
          issue('date_blocked', kind: 'venue', supplier: 'Mayor Cruz'),
        ]),
        needing('e3', 'Launch', [
          issue('unavailable', kind: 'service', item: 'Photographer'),
        ]),
      ]);

      await pump(tester, const EventOverviewPage());

      expect(
        find.text(
          'Maria Provider declined Garden wedding. Pick a replacement.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Mayor Cruz blocked a day of Reunion. Pick another venue or date.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Photographer is no longer available for Launch. Pick a replacement.',
        ),
        findsOneWidget,
      );
      expect(find.text("You're all caught up."), findsNothing);
    });

    testWidgets('shows five and says how many more', (tester) async {
      stubHome([
        for (var i = 1; i <= 7; i++)
          needing('e$i', 'Event $i', [issue('declined')]),
      ]);

      await pump(tester, const EventOverviewPage());

      expect(find.textContaining('declined Event'), findsNWidgets(5));
      expect(find.text('and 2 more need a replacement'), findsOneWidget);
    });

    testWidgets('is all clear when no event has lost a Supplier', (
      tester,
    ) async {
      stubHome([]);

      await pump(tester, const EventOverviewPage());

      expect(find.text("You're all caught up."), findsOneWidget);
    });

    testWidgets('a failure reading it does not hide the rest of the home', (
      tester,
    ) async {
      stubHome([]);
      when(() => api.get(ApiEndpoints.eventsNeedingAttention))
          .thenThrow(const NetworkException());

      await pump(tester, const EventOverviewPage());

      expect(find.text('NEEDS YOUR ATTENTION'), findsOneWidget);
      expect(find.textContaining('Pick a replacement'), findsNothing);
    });

    testWidgets('tapping a row opens that booked event', (tester) async {
      stubHome([
        needing('e1', 'Garden wedding', [issue('declined')]),
        needing('e2', 'Reunion', [issue('unavailable', item: 'Photographer')]),
      ]);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const EventOverviewPage()),
          GoRoute(
            path: '${RouteNames.spaceEvent}/booked/:eventId',
            builder: (_, s) =>
                Scaffold(body: Text('booked ${s.pathParameters['eventId']}')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(_Session.new),
            spacesRepositoryProvider.overrideWithValue(
              SpacesRepository(api, 'u1'),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Reunion'));
      await tester.pumpAndSettle();

      expect(find.text('booked e2'), findsOneWidget);
    });
  });

  group('check-in', () {
    testWidgets('sends the code and shows what the server said', (
      tester,
    ) async {
      when(() => api.patch(any(), any())).thenAnswer(
        (_) async => {
          'data': {'message': 'Ada checked in'},
        },
      );
      await pump(tester, const CheckInPage());

      await tester.enterText(find.byType(TextFormField), 'FX-77');
      await tester.tap(find.text('Check in guest'));
      await tester.pumpAndSettle();

      verify(
        () => api.patch(ApiEndpoints.bookingCheckIn, {'ticketCode': 'FX-77'}),
      ).called(1);
      expect(find.text('Ada checked in'), findsOneWidget);
    });

    testWidgets('an empty code is not sent', (tester) async {
      await pump(tester, const CheckInPage());

      await tester.tap(find.text('Check in guest'));
      await tester.pumpAndSettle();

      verifyNever(() => api.patch(any(), any()));
    });

    testWidgets('shows why the server refused', (tester) async {
      when(() => api.patch(any(), any())).thenThrow(
        const ServerException('Ticket already used'),
      );
      await pump(tester, const CheckInPage());

      await tester.enterText(find.byType(TextFormField), 'FX-77');
      await tester.tap(find.text('Check in guest'));
      await tester.pumpAndSettle();

      expect(find.text('Ticket already used'), findsOneWidget);
    });

    testWidgets('has a fallback message for an unexpected failure', (
      tester,
    ) async {
      when(() => api.patch(any(), any())).thenThrow(Exception('boom'));
      await pump(tester, const CheckInPage());

      await tester.enterText(find.byType(TextFormField), 'FX-77');
      await tester.tap(find.text('Check in guest'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "We couldn't check that guest in. Check the code and try again.",
        ),
        findsOneWidget,
      );
    });
  });
}
