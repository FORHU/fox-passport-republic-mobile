import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/register_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/reset_password_page.dart';
import 'package:flutter_template/features/auth/presentation/pages/verify_email_page.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/features/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter_template/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_template/features/passport/presentation/pages/passport_page.dart';
import 'package:flutter_template/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_template/features/search/presentation/pages/search_page.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/features/welcome/presentation/pages/welcome_page.dart';
import 'package:flutter_template/routes/route_names.dart';
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
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RouteNames.search,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: RouteNames.tickets,
            builder: (context, state) => const TicketsPage(),
          ),
          GoRoute(
            path: RouteNames.passport,
            builder: (context, state) => const PassportPage(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: RouteNames.notifications,
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
    ],
  );
});
