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
import 'package:flutter_template/features/spaces/presentation/pages/space_listings_page.dart';
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

  group('listings', () {
    testWidgets('lists your venues with their status', (tester) async {
      when(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'data': [
            {
              'id': 'v1',
              'name': 'Sky Hall',
              'status': 'available',
              'city': 'Baguio',
            },
            {'id': 'v2', 'name': 'Old Barn', 'status': 'pending'},
          ],
        },
      );

      await pump(tester, const SpaceListingsPage(kind: ListingKind.venues));

      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Baguio'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Manage on the web'), findsOneWidget);
    });

    testWidgets('your events come from the event list', (tester) async {
      when(() => api.get(ApiEndpoints.events, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'templates': [
            {'id': 'e1', 'name': 'Bonfire Night', 'status': 'published'},
          ],
        },
      );

      await pump(tester, const SpaceListingsPage(kind: ListingKind.events));

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Bonfire Night'), findsOneWidget);
    });

    testWidgets('says what to do when there is nothing listed yet', (
      tester,
    ) async {
      when(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .thenAnswer((_) async => {'data': <Object>[]});

      await pump(tester, const SpaceListingsPage(kind: ListingKind.venues));

      expect(find.textContaining("haven't listed a venue"), findsOneWidget);
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
