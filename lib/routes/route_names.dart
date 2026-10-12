/// Path constants for go_router. Reference these instead of raw strings.
class RouteNames {
  RouteNames._();

  /// First-launch carousel, shown once before sign-in.
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  /// Builds `/verify-email?email=...` (email is query-encoded).
  static String verifyEmailFor(String email) =>
      Uri(path: verifyEmail, queryParameters: {'email': email}).toString();

  /// Builds `/reset-password?email=...`.
  static String resetPasswordFor(String email) =>
      Uri(path: resetPassword, queryParameters: {'email': email}).toString();

  /// Bottom-nav tabs.
  static const String home = '/';
  static const String search = '/search';
  static const String tickets = '/tickets';
  static const String passport = '/passport';
  static const String profile = '/profile';

  /// Pushed from the app-bar bell.
  static const String notifications = '/notifications';
}
