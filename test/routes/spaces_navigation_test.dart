import 'dart:async';

// The Venue and Event spaces, driven through the real router: a space needs
// its role, the app opens in the space last worked in, and switching works.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/app.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/event/presentation/pages/event_detail_page.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_page.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/event_calendar_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/partners_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_more_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/routes/app_routes.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Session extends AuthController {
  _Session(this.roles);

  final List<String> roles;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'ada@example.com',
          name: 'Ada',
          roleType: roles,
        ),
      );
}

void main() {
  late GoRouter router;
  late SharedPreferences prefs;

  Future<void> boot(
    WidgetTester tester, {
    required List<String> roles,
    String? savedSpace,
    List<Override> overrides = const [],
  }) async {
    AppConfig.instance = const AppConfig.dev();
    SharedPreferences.setMockInitialValues({
      'welcome_seen': true,
      'onboarding_seen': true,
      'location_prompt_seen': true,
      if (savedSpace != null) 'active_space_u1': savedSpace,
    });
    prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => _Session(roles)),
        realtimeServiceProvider.overrideWithValue(null),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    router = container.read(goRouterProvider);
    await settle(tester);
  }

  String where() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 60));
  }

  testWidgets('a Citizen with no role cannot open a space', (tester) async {
    await boot(tester, roles: const []);

    router.go(RouteNames.spaceVenue);
    await settle(tester);

    expect(where(), RouteNames.home);
    expect(find.text('Requests'), findsNothing);
    // And has no switcher: nothing to switch to.
    expect(find.text('Switch space'), findsNothing);
    await finish(tester);
  });

  testWidgets('a VenueFoxer cannot open the Event space', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);

    router.go(RouteNames.spaceEvent);
    await settle(tester);

    expect(where(), RouteNames.home);
    await finish(tester);
  });

  testWidgets('a VenueFoxer opens the Venue space with its own tabs', (
    tester,
  ) async {
    await boot(tester, roles: const ['venueFoxer']);

    router.go(RouteNames.spaceVenue);
    await settle(tester);

    expect(where(), RouteNames.spaceVenue);
    for (final tab in ['Overview', 'Venues', 'Calendar', 'Earnings', 'More']) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    // The Citizen bar is not there.
    expect(find.text('Bookings'), findsNothing);
    expect(find.text('Passport'), findsNothing);
    await finish(tester);
  });

  testWidgets('the Venue space moves between its five tabs', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);
    router.go(RouteNames.spaceVenue);
    await settle(tester);

    for (final (label, path) in [
      ('Venues', RouteNames.spaceVenueVenues),
      ('Calendar', RouteNames.spaceVenueCalendar),
      ('Earnings', RouteNames.spaceVenueEarnings),
      ('More', RouteNames.spaceVenueMore),
      ('Overview', RouteNames.spaceVenue),
    ]) {
      await tester.tap(find.text(label).last);
      await settle(tester);
      expect(where(), path, reason: label);
    }
    await finish(tester);
  });

  testWidgets('More opens Requests, and back returns to More', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);
    router.go(RouteNames.spaceVenueMore);
    await settle(tester);

    await tester.tap(find.text('Requests'));
    await settle(tester);
    expect(find.byType(VenueRequestsPage), findsOneWidget);

    router.pop();
    await settle(tester);
    expect(find.byType(VenueMorePage), findsOneWidget);
    await finish(tester);
  });

  testWidgets('More opens Messages with a way back', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);
    router.go(RouteNames.spaceVenueMore);
    await settle(tester);

    await tester.tap(find.text('Messages'));
    await settle(tester);
    expect(find.byType(MessagesPage), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(VenueMorePage), findsOneWidget);
    await finish(tester);
  });

  testWidgets('a venue opens its hub inside the Venues tab', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);

    router.go(RouteNames.spaceVenueHub('v1'));
    await settle(tester);

    expect(where(), RouteNames.spaceVenueHub('v1'));
    // Still inside the Venue space, with its bottom bar.
    expect(find.text('Earnings'), findsWidgets);
    await finish(tester);
  });

  testWidgets('Add venue opens the studio, and back returns to the tab', (
    tester,
  ) async {
    await boot(tester, roles: const ['venueFoxer']);
    router.go(RouteNames.spaceVenueVenues);
    await settle(tester);

    await tester.tap(find.text('Add venue'));
    await settle(tester);

    expect(find.text('New venue'), findsOneWidget);
    expect(find.text('Venue name'), findsOneWidget);

    router.pop();
    await settle(tester);
    expect(find.text('New venue'), findsNothing);
    expect(where(), RouteNames.spaceVenueVenues);
    await finish(tester);
  });

  testWidgets('More opens Partners, and back returns to More', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);
    router.go(RouteNames.spaceVenueMore);
    await settle(tester);

    await tester.tap(find.text('Partners'));
    await settle(tester);
    expect(find.byType(PartnersPage), findsOneWidget);

    router.pop();
    await settle(tester);
    expect(where(), RouteNames.spaceVenueMore);
    await finish(tester);
  });

  testWidgets('the Event space has Events, Calendar, Check-in and Messages', (
    tester,
  ) async {
    await boot(tester, roles: const ['eventFoxer']);
    router.go(RouteNames.spaceEvent);
    await settle(tester);

    for (final tab in ['Events', 'Calendar', 'Check-in', 'Messages']) {
      expect(find.text(tab), findsWidgets);
    }

    await tester.tap(find.text('Calendar'));
    await settle(tester);
    expect(where(), RouteNames.spaceEventCalendar);
    expect(find.byType(EventCalendarPage), findsOneWidget);

    await tester.tap(find.text('Check-in'));
    await settle(tester);
    expect(where(), RouteNames.spaceEventCheckIn);
    await finish(tester);
  });

  testWidgets('tapping an event opens its page, and back returns', (
    tester,
  ) async {
    await boot(
      tester,
      roles: const ['eventFoxer'],
      overrides: [
        myEventsProvider.overrideWith(
          (ref) async => const [
            SpaceListing(id: 'e1', name: 'Ada Birthday', status: 'draft'),
          ],
        ),
      ],
    );
    router.go(RouteNames.spaceEvent);
    await settle(tester);

    await tester.tap(find.text('Ada Birthday'));
    await settle(tester);
    expect(find.byType(EventDetailPage), findsOneWidget);

    router.pop();
    await settle(tester);
    expect(find.byType(EventDetailPage), findsNothing);
    expect(find.text('Ada Birthday'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the Event space opens its venue partners', (tester) async {
    await boot(
      tester,
      roles: const ['eventFoxer'],
      overrides: [myEventsProvider.overrideWith((ref) async => const [])],
    );
    router.go(RouteNames.spaceEvent);
    await settle(tester);

    await tester.tap(find.text('Venue partners'));
    await settle(tester);
    expect(find.byType(PartnersPage), findsOneWidget);

    router.pop();
    await settle(tester);
    expect(where(), RouteNames.spaceEvent);
    await finish(tester);
  });

  testWidgets('the studio can edit a venue by its id', (tester) async {
    await boot(tester, roles: const ['venueFoxer']);

    unawaited(router.push(RouteNames.spaceVenueStudioEdit('v1')));
    await settle(tester);

    expect(find.text('Edit venue'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('the app opens in the space they last worked in', (
    tester,
  ) async {
    await boot(tester, roles: const ['venueFoxer'], savedSpace: 'venue');

    expect(where(), RouteNames.spaceVenue);
    await finish(tester);
  });

  testWidgets('a saved space they no longer hold the role for is ignored', (
    tester,
  ) async {
    await boot(tester, roles: const ['eventFoxer'], savedSpace: 'venue');

    expect(where(), RouteNames.home);
    await finish(tester);
  });

  testWidgets('switching to Citizen stays in Citizen, and is remembered', (
    tester,
  ) async {
    await boot(tester, roles: const ['venueFoxer'], savedSpace: 'venue');
    expect(where(), RouteNames.spaceVenue);

    // The button on the page names the space they are in.
    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await settle(tester);
    expect(find.text('Switch space'), findsOneWidget);
    await tester.tap(find.text('Citizen'));
    await settle(tester);

    expect(where(), RouteNames.home);
    expect(find.text('Passport'), findsWidgets);
    expect(prefs.getString('active_space_u1'), 'citizen');
    await finish(tester);
  });

  testWidgets('from Citizen, the switcher opens the Event space', (
    tester,
  ) async {
    await boot(tester, roles: const ['eventFoxer']);
    expect(where(), RouteNames.home);

    router.go(RouteNames.passport);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await settle(tester);
    await tester.tap(find.text('Event'));
    await settle(tester);

    expect(where(), RouteNames.spaceEvent);
    expect(prefs.getString('active_space_u1'), 'event');
    for (final tab in ['Events', 'Check-in', 'Messages']) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    await finish(tester);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
