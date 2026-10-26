import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter_template/features/blocks/presentation/pages/blocked_users_page.dart';
import 'package:flutter_template/features/booking/presentation/pages/booking_flow_page.dart';
import 'package:flutter_template/features/booking/presentation/pages/item_booking_page.dart';
import 'package:flutter_template/features/event/presentation/pages/event_detail_page.dart';
import 'package:flutter_template/features/event/presentation/pages/scheduled_event_detail_page.dart';
import 'package:flutter_template/features/foxer/presentation/pages/foxer_profile_page.dart';
import 'package:flutter_template/features/foxer/presentation/pages/match_request_page.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/features/location/presentation/pages/location_gate_page.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_chat_page.dart';
import 'package:flutter_template/features/messages/presentation/pages/messages_page.dart';
import 'package:flutter_template/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter_template/features/occasion/presentation/pages/all_categories_page.dart';
import 'package:flutter_template/features/occasion/presentation/pages/occasion_page.dart';
import 'package:flutter_template/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_template/features/passport/presentation/pages/passport_page.dart';
import 'package:flutter_template/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:flutter_template/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_template/features/republic/presentation/pages/compose_post_page.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/features/republic/presentation/pages/saved_posts_page.dart';
import 'package:flutter_template/features/roles/presentation/pages/roles_page.dart';
import 'package:flutter_template/features/search/presentation/pages/search_page.dart';
import 'package:flutter_template/features/settings/presentation/pages/change_password_page.dart';
import 'package:flutter_template/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/check_in_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/earnings_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/event_calendar_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/event_studio_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/events_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/partners_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/provider_listings_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/provider_more_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/provider_overview_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/team_detail_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/team_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_calendar_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_hub_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_more_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_overview_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_requests_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_studio_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venues_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_layout.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/features/venue/presentation/pages/venue_detail_page.dart';
import 'package:flutter_template/features/welcome/presentation/pages/welcome_page.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/widgets/main_layout.dart';
import 'package:go_router/go_router.dart';

/// Listenable helper to notify GoRouter whenever auth state changes.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// The app's router. `redirect` guards routes based on auth state; the login
/// form and logout button also navigate explicitly with `context.go(...)`.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = ref.read(authControllerProvider).isAuthenticated;
      final goingToLogin = state.matchedLocation == RouteNames.login;
      final goingToRegister = state.matchedLocation == RouteNames.register;
      // Reachable while signed out: OTP verification and password recovery.
      const publicPaths = {
        RouteNames.login,
        RouteNames.register,
        RouteNames.verifyEmail,
        RouteNames.forgotPassword,
        RouteNames.resetPassword,
      };

      final at = state.matchedLocation;

      if (!isAuth) {
        // First launch: the welcome carousel comes before anything else. Only
        // the recovery and register links (e.g. from an email) skip past it.
        final welcomeSeen = ref.read(storageServiceProvider).welcomeSeen;
        const bypassWelcome = {
          RouteNames.welcome,
          RouteNames.register,
          RouteNames.verifyEmail,
          RouteNames.forgotPassword,
          RouteNames.resetPassword,
        };
        if (!welcomeSeen && !bypassWelcome.contains(at)) {
          return RouteNames.welcome;
        }

        return (publicPaths.contains(at) || at == RouteNames.welcome)
            ? null
            : RouteNames.login;
      }

      // Onboarding gate: new users see it once.
      final seenOnboarding = ref.read(storageServiceProvider).onboardingSeen;
      if (!seenOnboarding) {
        final goingToOnboarding = at == RouteNames.onboarding;
        return goingToOnboarding ? null : RouteNames.onboarding;
      }

      // Location is asked once, before the app is used.
      final askedLocation = ref.read(storageServiceProvider).locationPromptSeen;
      if (!askedLocation) {
        return at == RouteNames.location ? null : RouteNames.location;
      }
      if (at == RouteNames.location) return RouteNames.home;

      // The carousel is a signed-out screen.
      if (goingToLogin || goingToRegister || at == RouteNames.welcome) {
        return RouteNames.home;
      }

      // A space needs the role that opens it.
      final roles = ref.read(heldRolesProvider);
      final inSpace = AppSpace.forPath(at);
      if (inSpace != null && !inSpace.isAvailableTo(roles)) {
        return RouteNames.home;
      }
      // Opening the app, or landing on Home, goes to the space they were last
      // working in. Switching back to Citizen saves Citizen first, so this
      // does not pull them out again.
      if (at == RouteNames.home) {
        final active = ref.read(activeSpaceProvider);
        if (active != AppSpace.citizen) return active.root;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        builder: (context, state) =>
            VerifyEmailPage(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (context, state) =>
            ResetPasswordPage(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.location,
        builder: (context, state) => const LocationGatePage(),
      ),
      GoRoute(
        path: RouteNames.roles,
        builder: (context, state) => const RolesPage(),
      ),
      GoRoute(
        path: '/occasion/:name',
        builder: (context, state) => OccasionPage(
          occasion:
              Occasion.fromName(state.pathParameters['name']) ?? Occasion.other,
        ),
      ),
      GoRoute(
        path: RouteNames.allCategories,
        builder: (context, state) => const AllCategoriesPage(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: RouteNames.blockedUsers,
        builder: (context, state) => const BlockedUsersPage(),
      ),
      // Profile is opened from both Passport and Settings, so it is a screen
      // of its own, not part of the Passport tab: a route inside a tab cannot
      // be pushed from outside it (the tab's page would be on the stack twice).
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteNames.profileEdit,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteNames.spaceVenueStudio,
        builder: (context, state) => const VenueStudioPage(),
      ),
      GoRoute(
        path: '${RouteNames.spaceVenueStudio}/:venueId',
        builder: (context, state) =>
            VenueStudioPage(venueId: state.pathParameters['venueId']),
      ),
      GoRoute(
        path: RouteNames.spaceTeamVenues,
        builder: (context, state) => const TeamPage(events: false),
      ),
      GoRoute(
        path: RouteNames.spaceTeamEvents,
        builder: (context, state) => const TeamPage(events: true),
      ),
      GoRoute(
        path: RouteNames.spaceTeamDetail,
        // Opened with the venue or event as `extra`; without it (a restored
        // link) there is nothing to show, so go back to the list.
        redirect: (context, state) =>
            state.extra is TeamTarget ? null : RouteNames.spaceVenue,
        builder: (context, state) =>
            TeamDetailPage(target: state.extra! as TeamTarget),
      ),
      GoRoute(
        path: RouteNames.spaceEventStudio,
        builder: (context, state) => const EventStudioPage(),
      ),
      GoRoute(
        path: '${RouteNames.spaceEventStudio}/:eventId',
        builder: (context, state) =>
            EventStudioPage(eventId: state.pathParameters['eventId']),
      ),
      // A chat is full screen, outside the shell, so the bottom navigation is
      // not drawn over the composer.
      GoRoute(
        path: '${RouteNames.messages}/:conversationId',
        builder: (context, state) => MessagesChatPage(
          conversationId: state.pathParameters['conversationId']!,
          conversation:
              state.extra is Conversation ? state.extra! as Conversation : null,
        ),
      ),
      GoRoute(
        path: RouteNames.book,
        // The venue travels as `extra`; without it (a stale deep link) go back
        // to Search rather than show an empty flow.
        redirect: (context, state) =>
            state.extra is CatalogItem || state.extra is EventBookingArgs
                ? null
                : RouteNames.search,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is EventBookingArgs) {
            return BookingFlowPage(
              venue: extra.item,
              package: extra.package,
              excluded: extra.excluded,
            );
          }
          return BookingFlowPage(venue: extra! as CatalogItem);
        },
      ),
      GoRoute(
        path: RouteNames.republicCompose,
        builder: (context, state) => const ComposePostPage(),
      ),
      GoRoute(
        path: RouteNames.republicSaved,
        builder: (context, state) => const SavedPostsPage(),
      ),
      GoRoute(
        path: RouteNames.itemBooking,
        redirect: (context, state) =>
            state.extra is CatalogItem ? null : RouteNames.search,
        builder: (context, state) =>
            ItemBookingPage(item: state.extra! as CatalogItem),
      ),
      GoRoute(
        path: RouteNames.foxer,
        redirect: (context, state) =>
            state.extra is CatalogItem ? null : RouteNames.search,
        builder: (context, state) =>
            FoxerProfilePage(item: state.extra! as CatalogItem),
      ),
      GoRoute(
        path: RouteNames.match,
        redirect: (context, state) =>
            state.extra is CatalogItem ? null : RouteNames.search,
        builder: (context, state) =>
            MatchRequestPage(item: state.extra! as CatalogItem),
      ),
      GoRoute(
        path: RouteNames.venueDetail,
        redirect: (context, state) =>
            state.extra is CatalogItem ? null : RouteNames.search,
        builder: (context, state) =>
            VenueDetailPage(item: state.extra! as CatalogItem),
      ),
      GoRoute(
        path: RouteNames.eventDetail,
        redirect: (context, state) =>
            state.extra is CatalogItem ? null : RouteNames.search,
        builder: (context, state) =>
            EventDetailPage(item: state.extra! as CatalogItem),
      ),
      GoRoute(
        path: RouteNames.scheduledEventDetail,
        redirect: (context, state) =>
            state.extra is CatalogItem ? null : RouteNames.search,
        builder: (context, state) =>
            ScheduledEventDetailPage(item: state.extra! as CatalogItem),
      ),
      // One navigator per tab, kept alive side by side: switching tabs keeps
      // each tab's own stack, scroll position and typed text.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainLayout(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
              GoRoute(
                path: RouteNames.notifications,
                builder: (context, state) => const NotificationsPage(),
              ),
              // Search lives under Home: it is opened from Home's search bar.
              GoRoute(
                path: RouteNames.search,
                builder: (context, state) => SearchPage(
                  initialKind: CatalogKind.fromParam(
                    state.uri.queryParameters['kind'],
                  ),
                  initialCity: state.uri.queryParameters['city'],
                  initialMinCapacity: int.tryParse(
                    state.uri.queryParameters['capacity'] ?? '',
                  ),
                  initialDate: DateTime.tryParse(
                    state.uri.queryParameters['date'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.republic,
                builder: (context, state) => const RepublicPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.tickets,
                builder: (context, state) => TicketsPage(
                  initialSegment: state.uri.queryParameters['segment'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.messages,
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.passport,
                builder: (context, state) => const PassportPage(),
              ),
            ],
          ),
        ],
      ),
      // The Venue space: its own tabs and bottom bar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => Consumer(
          // A count of requests waiting for a reply, on the Overview tab.
          builder: (context, ref, _) => SpaceLayout(
            navigationShell: navigationShell,
            items: SpaceLayout.venueItems(
              context,
              partnersWaiting:
                  ref.watch(partnersWaitingProvider(PartnerSide.mayor)),
              waiting: ref.watch(venueRequestsProvider).maybeWhen(
                    data: (list) => list.where((r) => r.needsReply).length,
                    orElse: () => 0,
                  ),
            ),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceVenue,
                builder: (context, state) => const VenueOverviewPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceVenueVenues,
                builder: (context, state) => const VenuesPage(),
                routes: [
                  GoRoute(
                    path: ':venueId',
                    builder: (context, state) => VenueHubPage(
                      venueId: state.pathParameters['venueId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceVenueCalendar,
                builder: (context, state) => VenueCalendarPage(
                  venueId: state.uri.queryParameters['venue'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceVenueEarnings,
                builder: (context, state) => const EarningsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceVenueMore,
                builder: (context, state) => const VenueMorePage(),
                routes: [
                  GoRoute(
                    path: 'requests',
                    builder: (context, state) => const VenueRequestsPage(),
                  ),
                  GoRoute(
                    path: 'partners',
                    builder: (context, state) =>
                        const PartnersPage(side: PartnerSide.mayor),
                  ),
                  GoRoute(
                    path: 'check-in',
                    builder: (context, state) => const CheckInPage(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) =>
                        const MessagesPage(showBack: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // The Event space.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => Consumer(
          // A count of partnerships waiting for an answer, on the Events tab.
          builder: (context, ref, _) => SpaceLayout(
            navigationShell: navigationShell,
            items: SpaceLayout.eventItems(
              context,
              partnersWaiting:
                  ref.watch(partnersWaitingProvider(PartnerSide.eventFoxer)),
            ),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceEvent,
                builder: (context, state) => const EventsPage(),
                routes: [
                  GoRoute(
                    path: 'partners',
                    builder: (context, state) =>
                        const PartnersPage(side: PartnerSide.eventFoxer),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceEventCalendar,
                builder: (context, state) => const EventCalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceEventCheckIn,
                builder: (context, state) => const CheckInPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.spaceEventMessages,
                builder: (context, state) => const MessagesPage(),
              ),
            ],
          ),
        ],
      ),
      // The Gear and Services spaces share their screens.
      for (final kind in ProviderKind.values) _providerShell(kind),
    ],
  );
});

/// The shell of a provider's space: Overview, Listings, Calendar, Earnings and
/// More, for what [kind] supplies.
StatefulShellRoute _providerShell(ProviderKind kind) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => Consumer(
      // A count of requests waiting for a reply, on the Overview tab.
      builder: (context, ref, _) => SpaceLayout(
        navigationShell: navigationShell,
        items: SpaceLayout.providerItems(
          context,
          listings: listingsLabel(
            context.l10n,
            kind,
            roles: ref.watch(heldRolesProvider),
          ),
          waiting: ref.watch(supplyRequestsProvider(kind.request)).maybeWhen(
                data: (list) => list.where((r) => r.needsReply).length,
                orElse: () => 0,
              ),
        ),
      ),
    ),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: kind.root,
            builder: (context, state) => ProviderOverviewPage(kind: kind),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: kind.listings,
            builder: (context, state) => ProviderListingsPage(kind: kind),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: kind.calendar,
            builder: (context, state) => const EventCalendarPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: kind.earnings,
            builder: (context, state) => const EarningsPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: kind.more,
            builder: (context, state) => ProviderMorePage(kind: kind),
            routes: [
              GoRoute(
                path: 'requests',
                builder: (context, state) => VenueRequestsPage(provider: kind),
              ),
              GoRoute(
                path: 'messages',
                builder: (context, state) => const MessagesPage(showBack: true),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
