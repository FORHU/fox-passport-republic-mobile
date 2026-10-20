import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
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
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/features/roles/presentation/pages/roles_page.dart';
import 'package:flutter_template/features/search/presentation/pages/search_page.dart';
import 'package:flutter_template/features/settings/presentation/pages/change_password_page.dart';
import 'package:flutter_template/features/settings/presentation/pages/settings_page.dart';
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
        path: RouteNames.republic,
        builder: (context, state) => const RepublicPage(),
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
            ],
          ),
          StatefulShellBranch(
            routes: [
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
    ],
  );
});
