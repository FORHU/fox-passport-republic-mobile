import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/earnings_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_hub_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_more_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_overview_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venues_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
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

const _sky = SpaceListing(
  id: 'v1',
  name: 'Sky Hall',
  status: 'available',
  city: 'Baguio',
);
const _barn = SpaceListing(id: 'v2', name: 'Old Barn', status: 'pending');

VenueRequest _request(String id, {bool needsReply = true}) => VenueRequest(
      id: id,
      venueName: 'Sky Hall',
      eventName: 'Ada Birthday',
      status: needsReply ? RequestStatus.awaitingYou : RequestStatus.approved,
      clientName: 'Ada',
      price: 25000,
    );

CalendarEntry _booking(String title, VenueHold hold, {int inDays = 3}) {
  final day = DateTime.now().add(Duration(days: inDays));
  return CalendarEntry(
    id: title,
    role: CalendarRole.venue,
    title: title,
    start: DateTime(day.year, day.month, day.day, 18),
    end: DateTime(day.year, day.month, day.day, 23),
    status: 'approved',
    venueId: 'v1',
    venueName: 'Sky Hall',
    hold: hold,
  );
}

void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(() => api.patch(any(), any())).thenAnswer((_) async => {});
  });

  /// [home] at `/`, with a marker page at every place it might go, so a test can
  /// see where a tap led without building those screens.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<SpaceListing> venues = const [],
    List<VenueRequest> requests = const [],
    PayoutSummary payouts = const PayoutSummary(),
    StripeStatus stripe = const StripeStatus(),
    List<CalendarEntry> calendar = const [],
  }) async {
    _tall(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Widget marker(String name) => Scaffold(body: Text('AT $name'));
    Object? extra;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        for (final path in [
          RouteNames.spaceVenueRequests,
          RouteNames.spaceVenueCheckIn,
          RouteNames.spaceVenueMessages,
          RouteNames.spaceVenueCalendar,
          RouteNames.spaceVenueVenues,
          RouteNames.settings,
          RouteNames.spaceVenueMore,
        ])
          GoRoute(path: path, builder: (_, s) => marker(s.uri.toString())),
        GoRoute(
          path: '/space/venue/venues/:id',
          builder: (_, s) => marker('hub ${s.pathParameters['id']}'),
        ),
        GoRoute(
          path: RouteNames.venueDetail,
          builder: (_, s) {
            extra = s.extra;
            return marker('public ${(extra! as CatalogItem).title}');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(_Session.new),
          spacesRepositoryProvider
              .overrideWithValue(SpacesRepository(api, 'u1')),
          myVenuesProvider.overrideWith((ref) async => venues),
          venueRequestsProvider.overrideWith((ref) async => requests),
          payoutsProvider.overrideWith((ref) async => payouts),
          stripeStatusProvider.overrideWith((ref) async => stripe),
          venueCalendarProvider.overrideWith((ref, range) async => calendar),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Overview', () {
    testWidgets('shows the numbers that matter', (tester) async {
      await pump(
        tester,
        const VenueOverviewPage(),
        venues: const [_sky, _barn],
        payouts: const PayoutSummary(
          totals: PayoutTotals(pending: 5000, paid: 12000),
        ),
        calendar: [
          _booking('Wedding', VenueHold.confirmed),
          _booking('Reunion', VenueHold.held, inDays: 5),
        ],
      );

      expect(find.text('1 of 2'), findsOneWidget); // venues live
      expect(find.text('2'), findsOneWidget); // bookings, next 30 days
      expect(find.text('₱12,000'), findsOneWidget); // paid out
      expect(find.text('₱5,000'), findsOneWidget); // pending
    });

    testWidgets('puts a request that needs a reply on top, to answer there', (
      tester,
    ) async {
      await pump(
        tester,
        const VenueOverviewPage(),
        requests: [_request('r1'), _request('r2', needsReply: false)],
      );

      expect(find.text('Needs your reply'), findsWidgets);
      // Only the one waiting for a reply is offered here.
      expect(find.text('Accept'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      verify(
        () => api.patch(
          ApiEndpoints.requestReview('r1'),
          {'type': 'venue', 'action': 'confirm'},
        ),
      ).called(1);
    });

    testWidgets('says when nothing is waiting or coming up', (tester) async {
      await pump(tester, const VenueOverviewPage());

      expect(find.text('Nothing is waiting for you.'), findsOneWidget);
      expect(find.text('No bookings in the next 30 days.'), findsOneWidget);
    });

    testWidgets('lists what is coming up, with where it stands', (
      tester,
    ) async {
      await pump(
        tester,
        const VenueOverviewPage(),
        calendar: [
          _booking('Wedding', VenueHold.confirmed),
          _booking('Reunion', VenueHold.held, inDays: 5),
        ],
      );

      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Reunion'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Held'), findsOneWidget);
    });

    testWidgets('a booking waiting for a reply is not listed twice', (
      tester,
    ) async {
      await pump(
        tester,
        const VenueOverviewPage(),
        requests: [_request('r1')],
        calendar: [_booking('Ada Birthday', VenueHold.awaitingReply)],
      );

      // It counts as a booking, but it is in Needs your reply, not Coming up.
      expect(find.text('No bookings in the next 30 days.'), findsOneWidget);
    });

    testWidgets('the quick actions go where they say', (tester) async {
      await pump(tester, const VenueOverviewPage());

      await tester.tap(find.text('Check in a guest'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${RouteNames.spaceVenueCheckIn}'), findsOneWidget);
    });
  });

  group('Venues', () {
    testWidgets('lists each venue with its town and status', (tester) async {
      await pump(tester, const VenuesPage(), venues: const [_sky, _barn]);

      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Baguio'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Old Barn'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Add venue'), findsOneWidget);
    });

    testWidgets('says what to do when there is no venue yet', (tester) async {
      await pump(tester, const VenuesPage());

      expect(find.textContaining("haven't listed a venue"), findsOneWidget);
    });

    testWidgets('tapping a venue opens its hub', (tester) async {
      await pump(tester, const VenuesPage(), venues: const [_sky]);

      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();

      expect(find.text('AT hub v1'), findsOneWidget);
    });
  });

  group('Venue hub', () {
    testWidgets('shows the venue and what can be done with it', (tester) async {
      await pump(
        tester,
        const VenueHubPage(venueId: 'v1'),
        venues: const [_sky],
      );

      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Edit details'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('View public page'), findsOneWidget);
    });

    testWidgets('Availability opens the calendar on that venue', (
      tester,
    ) async {
      await pump(
        tester,
        const VenueHubPage(venueId: 'v1'),
        venues: const [_sky],
      );

      await tester.tap(find.text('Availability'));
      await tester.pumpAndSettle();

      expect(
        find.text('AT ${RouteNames.spaceVenueCalendar}?venue=v1'),
        findsOneWidget,
      );
    });

    testWidgets('View public page opens the venue as guests see it', (
      tester,
    ) async {
      await pump(
        tester,
        const VenueHubPage(venueId: 'v1'),
        venues: const [_sky],
      );

      await tester.tap(find.text('View public page'));
      await tester.pumpAndSettle();

      expect(find.text('AT public Sky Hall'), findsOneWidget);
    });

    testWidgets('a venue that is not theirs is not found', (tester) async {
      await pump(
        tester,
        const VenueHubPage(venueId: 'other'),
        venues: const [_sky],
      );

      expect(find.text('Edit details'), findsNothing);
    });
  });

  group('Earnings', () {
    testWidgets('shows what is pending and paid, and the latest payouts', (
      tester,
    ) async {
      await pump(
        tester,
        const EarningsPage(),
        payouts: const PayoutSummary(
          totals: PayoutTotals(pending: 5000, paid: 12000),
          rows: [
            PayoutRow(
              id: 'p1',
              amount: 8000,
              status: 'paid',
              source: 'event_venue_transaction',
            ),
            PayoutRow(
              id: 'p2',
              amount: 5000,
              status: 'pending',
              source: 'event_asset_transaction',
            ),
          ],
        ),
      );

      expect(find.text('₱5,000'), findsWidgets);
      expect(find.text('₱12,000'), findsOneWidget);
      expect(find.text('₱8,000'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      expect(find.textContaining('Venue booking'), findsOneWidget);
      expect(find.textContaining('Other'), findsOneWidget);
    });

    testWidgets('invites them to set up payouts when they are not on', (
      tester,
    ) async {
      await pump(tester, const EarningsPage());

      expect(find.text('Payout setup'), findsOneWidget);
      expect(find.text('Set up payouts'), findsOneWidget);
    });

    testWidgets('says to finish setup once an account was started', (
      tester,
    ) async {
      await pump(
        tester,
        const EarningsPage(),
        stripe: const StripeStatus(hasAccount: true),
      );

      expect(find.text('Finish payout setup'), findsOneWidget);
    });

    testWidgets('says payouts are on, with nothing more to do', (tester) async {
      await pump(
        tester,
        const EarningsPage(),
        stripe: const StripeStatus(
          hasAccount: true,
          onboardingComplete: true,
          payoutsEnabled: true,
        ),
      );

      expect(find.text('Payouts are on'), findsOneWidget);
      expect(find.text('Set up payouts'), findsNothing);
      expect(find.text('Finish payout setup'), findsNothing);
    });

    testWidgets('says so when there are no payouts yet', (tester) async {
      await pump(tester, const EarningsPage());

      expect(find.textContaining('No payouts yet'), findsOneWidget);
    });
  });

  group('More', () {
    testWidgets('has the things that are not a tab', (tester) async {
      await pump(tester, const VenueMorePage());

      for (final row in [
        'Requests',
        'Check-in',
        'Messages',
        'Switch space',
        'Settings',
        'Manage on the web',
      ]) {
        expect(find.text(row), findsOneWidget, reason: row);
      }
    });

    testWidgets('shows how many requests need a reply', (tester) async {
      await pump(
        tester,
        const VenueMorePage(),
        requests: [
          _request('r1'),
          _request('r2'),
          _request('r3', needsReply: false),
        ],
      );

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Requests, Check-in and Messages open their screens', (
      tester,
    ) async {
      await pump(tester, const VenueMorePage());

      await tester.tap(find.text('Check-in'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${RouteNames.spaceVenueCheckIn}'), findsOneWidget);
    });
  });
}
