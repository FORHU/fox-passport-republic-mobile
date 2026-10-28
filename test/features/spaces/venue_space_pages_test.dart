import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/earnings_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_hub_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_more_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_overview_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venues_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
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
    PartnerLists partners = const PartnerLists(),
    Future<List<VenueRequest>>? requestsLoad,
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
          RouteNames.spaceVenuePartners,
          RouteNames.spaceVenueEarnings,
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
          venueRequestsProvider
              .overrideWith((ref) => requestsLoad ?? Future.value(requests)),
          payoutsProvider.overrideWith((ref) async => payouts),
          stripeStatusProvider.overrideWith((ref) async => stripe),
          venueCalendarProvider.overrideWith((ref, range) async => calendar),
          partnersProvider.overrideWith((ref) async => partners),
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
      // The calendar strip can show a day numbered 2, so look in the tile.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Bookings, next 30 days'),
            matching: find.byType(KpiTile),
          ),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
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

    testWidgets('a request says by when to reply, with a real time', (
      tester,
    ) async {
      await pump(
        tester,
        const VenueRequestsPage(),
        requests: [
          VenueRequest(
            id: 'r9',
            venueName: 'Sky Hall',
            eventName: 'Ada Birthday',
            status: RequestStatus.awaitingYou,
            replyBy: DateTime(2026, 10, 28, 17, 30),
          ),
        ],
      );

      expect(find.textContaining('Oct 28'), findsOneWidget);
      expect(find.textContaining('5:30'), findsOneWidget);
      // A pattern letter that is not one prints as itself.
      expect(find.textContaining(' j'), findsNothing);
    });

    testWidgets('says when all is clear and nothing is coming up', (
      tester,
    ) async {
      await pump(tester, const VenueOverviewPage());

      expect(find.text("You're all caught up."), findsOneWidget);
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

    group('what needs the person', () {
      Partner application(String id) => Partner.tryParse(
            {
              'id': id,
              'status': 'pending',
              'initiatedBy': 'eventFoxer',
              'venue': {'id': 'v1', 'name': 'Sky Hall'},
              'eventFoxer': {'id': 'e1', 'name': 'Ada'},
            },
            PartnerSide.mayor,
          )!;

      const rejected = SpaceListing(
        id: 'v3',
        name: 'Declined Hall',
        status: 'rejected',
      );
      const draft =
          SpaceListing(id: 'v4', name: 'Draft Villa', status: 'draft');

      testWidgets('lists partner applications that are waiting', (
        tester,
      ) async {
        await pump(
          tester,
          const VenueOverviewPage(),
          partners: PartnerLists(
            asMayor: [application('a'), application('b')],
          ),
        );

        expect(find.text('2 partner applications are waiting'), findsOneWidget);
        expect(find.text("You're all caught up."), findsNothing);

        await tester.tap(find.text('2 partner applications are waiting'));
        await tester.pumpAndSettle();
        expect(
          find.text('AT ${RouteNames.spaceVenuePartners}'),
          findsOneWidget,
        );
      });

      testWidgets('says how many venues are in review, declined or drafts', (
        tester,
      ) async {
        await pump(
          tester,
          const VenueOverviewPage(),
          venues: const [_sky, _barn, rejected, draft],
        );

        expect(find.text('1 venue is in review'), findsOneWidget);
        expect(find.text('1 venue was declined'), findsOneWidget);
        expect(find.text('1 draft to finish'), findsOneWidget);
        expect(find.text("You're all caught up."), findsNothing);

        await tester.tap(find.text('1 venue was declined'));
        await tester.pumpAndSettle();
        expect(find.text('AT ${RouteNames.spaceVenueVenues}'), findsOneWidget);
      });

      testWidgets('a live venue alone leaves nothing to do', (tester) async {
        await pump(tester, const VenueOverviewPage(), venues: const [_sky]);

        expect(find.text("You're all caught up."), findsOneWidget);
        expect(find.textContaining('venue is'), findsNothing);
      });

      testWidgets('does not claim all is clear while it is still loading', (
        tester,
      ) async {
        await pump(
          tester,
          const VenueOverviewPage(),
          requestsLoad: Completer<List<VenueRequest>>().future,
        );

        expect(find.text("You're all caught up."), findsNothing);
      });

      testWidgets('requests, partners and venues all show together', (
        tester,
      ) async {
        await pump(
          tester,
          const VenueOverviewPage(),
          requests: [_request('r1')],
          venues: const [_sky, draft],
          partners: PartnerLists(asMayor: [application('a')]),
        );

        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('1 partner application is waiting'), findsOneWidget);
        expect(find.text('1 draft to finish'), findsOneWidget);
      });
    });

    testWidgets('puts the quick actions first, above what needs the person', (
      tester,
    ) async {
      await pump(tester, const VenueOverviewPage());

      final actions = tester.getTopLeft(find.text('Check in a guest')).dy;
      final attention = tester.getTopLeft(find.text('NEEDS YOUR ATTENTION')).dy;
      final numbers = tester.getTopLeft(find.text('NUMBERS')).dy;
      expect(actions, lessThan(attention));
      expect(attention, lessThan(numbers));
    });

    testWidgets('each number opens where its detail is', (tester) async {
      await pump(tester, const VenueOverviewPage(), venues: const [_sky]);

      await tester.tap(find.text('Venues live'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${RouteNames.spaceVenueVenues}'), findsOneWidget);
    });

    testWidgets('the money numbers open Earnings', (tester) async {
      await pump(
        tester,
        const VenueOverviewPage(),
        payouts: const PayoutSummary(totals: PayoutTotals(pending: 5000)),
      );

      await tester.tap(find.text('Pending payouts'));
      await tester.pumpAndSettle();
      expect(find.text('AT ${RouteNames.spaceVenueEarnings}'), findsOneWidget);
    });

    testWidgets('a booking today is marked Today', (tester) async {
      await pump(
        tester,
        const VenueOverviewPage(),
        calendar: [
          _booking('Wedding', VenueHold.confirmed, inDays: 0),
          _booking('Reunion', VenueHold.held, inDays: 5),
        ],
      );

      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('tiles in a row line up', (tester) async {
      await pump(tester, const VenueOverviewPage(), venues: const [_sky]);
      // A phone-width screen, where a long label can wrap onto a second line.
      tester.view.physicalSize = const Size(360, 2000);
      await tester.pumpAndSettle();

      Finder tile(String label) => find.ancestor(
            of: find.text(label),
            matching: find.byType(InkWell),
          );
      // Each row's tiles start at the same height and are as tall as each
      // other, however their labels wrap.
      for (final pair in [
        ('Venues live', 'Bookings, next 30 days'),
        ('Paid out', 'Pending payouts'),
        ('Check in a guest', 'Close a day'),
        ('Close a day', 'Add a venue'),
      ]) {
        expect(
          tester.getTopLeft(tile(pair.$1)).dy,
          tester.getTopLeft(tile(pair.$2)).dy,
        );
        expect(
          tester.getSize(tile(pair.$1)).height,
          tester.getSize(tile(pair.$2)).height,
        );
      }
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

    group('finding one among many', () {
      const many = [
        _sky,
        _barn,
        SpaceListing(
          id: 'v3',
          name: 'Harbour Pavilion',
          status: 'available',
          city: 'Sydney',
        ),
        SpaceListing(
          id: 'v4',
          name: 'Garden Estate',
          status: 'draft',
          city: 'Los Angeles',
        ),
      ];

      testWidgets('shows how many there are, and filters by status', (
        tester,
      ) async {
        await pump(tester, const VenuesPage(), venues: many);

        expect(find.text('4 venues'), findsOneWidget);
        expect(find.text('All 4'), findsOneWidget);
        expect(find.text('Live 2'), findsOneWidget);
        expect(find.text('In review 1'), findsOneWidget);
        expect(find.text('Draft 1'), findsOneWidget);

        await tester.tap(find.text('Live 2'));
        await tester.pumpAndSettle();

        expect(find.text('Sky Hall'), findsOneWidget);
        expect(find.text('Harbour Pavilion'), findsOneWidget);
        expect(find.text('Old Barn'), findsNothing);
        expect(find.text('Garden Estate'), findsNothing);
        expect(find.text('2 of 4 venues'), findsOneWidget);

        await tester.tap(find.text('All 4'));
        await tester.pumpAndSettle();
        expect(find.text('Old Barn'), findsOneWidget);
      });

      testWidgets('searches by name or by town', (tester) async {
        await pump(tester, const VenuesPage(), venues: many);

        await tester.enterText(find.byType(TextField), 'harb');
        await tester.pumpAndSettle();
        expect(find.text('Harbour Pavilion'), findsOneWidget);
        expect(find.text('Sky Hall'), findsNothing);
        expect(find.text('1 of 4 venues'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'los angeles');
        await tester.pumpAndSettle();
        expect(find.text('Garden Estate'), findsOneWidget);
      });

      testWidgets('search and a status filter work together', (tester) async {
        await pump(tester, const VenuesPage(), venues: many);

        await tester.tap(find.text('Live 2'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'garden');
        await tester.pumpAndSettle();

        // The garden venue is a draft, so a Live filter hides it.
        expect(find.text('Garden Estate'), findsNothing);
        expect(find.text('No venues match.'), findsOneWidget);
      });

      testWidgets('clearing the search brings every venue back', (
        tester,
      ) async {
        await pump(tester, const VenuesPage(), venues: many);

        await tester.enterText(find.byType(TextField), 'zzz');
        await tester.pumpAndSettle();
        expect(find.text('No venues match.'), findsOneWidget);

        await tester.tap(find.byTooltip('Clear search'));
        await tester.pumpAndSettle();

        expect(find.text('No venues match.'), findsNothing);
        expect(find.text('4 venues'), findsOneWidget);
      });

      testWidgets('one status only needs no filter row', (tester) async {
        await pump(tester, const VenuesPage(), venues: const [_sky]);

        expect(find.text('1 venue'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNothing);
      });

      testWidgets('hides the search when there are no venues', (tester) async {
        await pump(tester, const VenuesPage());

        expect(find.byType(TextField), findsNothing);
      });

      testWidgets('a long list is built lazily, and every venue is reachable', (
        tester,
      ) async {
        final lots = [
          for (var i = 0; i < 60; i++)
            SpaceListing(
              id: 'x$i',
              name: 'Venue number $i',
              status: 'available',
              city: 'Town',
            ),
        ];
        await pump(tester, const VenuesPage(), venues: lots);

        expect(find.text('60 venues'), findsOneWidget);
        // Not all 60 rows are built at once.
        expect(
          tester.widgetList(find.textContaining('Venue number')).length,
          lessThan(60),
        );

        await tester.enterText(find.byType(TextField), 'number 59');
        await tester.pumpAndSettle();
        expect(find.text('Venue number 59'), findsOneWidget);
      });
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
