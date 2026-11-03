import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/presentation/pages/check_in_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/events_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.text('Decline this request?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Decline'));
      await tester.pumpAndSettle();

      verify(
        () => api.patch(
          ApiEndpoints.requestReview('r1'),
          {'type': 'venue', 'action': 'reject'},
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
      await tester.tap(find.text('Cancel'));
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
    }

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
      expect(find.text('Garden Party'), findsOneWidget);
      expect(find.text('2 events'), findsOneWidget);
    });

    testWidgets('puts the quick actions first', (tester) async {
      api_(events: [event('e1', 'Bonfire Night', 'published')]);
      await pump(tester, const EventsPage());

      final actions = tester.getTopLeft(find.text('Check in a guest')).dy;
      final attention = tester.getTopLeft(find.text('NEEDS YOUR ATTENTION')).dy;
      expect(actions, lessThan(attention));
      expect(find.text('Venue partners'), findsOneWidget);
      expect(find.text('New event'), findsOneWidget);
    });

    testWidgets('says when all is clear', (tester) async {
      api_(events: [event('e1', 'Bonfire Night', 'published')]);
      await pump(tester, const EventsPage());

      expect(find.text("You're all caught up."), findsOneWidget);
    });

    testWidgets('lists venue invitations waiting for an answer', (
      tester,
    ) async {
      api_(
        events: [event('e1', 'Bonfire Night', 'published')],
        invites: [invite('a'), invite('b')],
      );
      await pump(tester, const EventsPage());

      expect(find.text('2 venue invitations are waiting'), findsOneWidget);
      expect(find.text("You're all caught up."), findsNothing);
      // The Venue partners shortcut carries the count.
      expect(find.text('2'), findsOneWidget);
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
      await pump(tester, const EventsPage());

      expect(find.text('1 event is in review'), findsOneWidget);
      expect(find.text('1 event was declined'), findsOneWidget);
      expect(find.text('1 draft to finish'), findsOneWidget);
    });

    testWidgets('tapping a status row shows just those events', (
      tester,
    ) async {
      api_(
        events: [
          event('e1', 'Live One', 'published'),
          event('e2', 'Draft One', 'draft'),
        ],
      );
      await pump(tester, const EventsPage());

      await tester.tap(find.text('1 draft to finish'));
      await tester.pumpAndSettle();

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

    testWidgets('says so when the events cannot be loaded', (tester) async {
      when(() => api.get(ApiEndpoints.events, query: any(named: 'query')))
          .thenThrow(Exception('down'));
      await pump(tester, const EventsPage());

      expect(find.text("We couldn't load this right now."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
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
