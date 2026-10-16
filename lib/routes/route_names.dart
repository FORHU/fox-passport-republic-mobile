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

  /// `/search?kind=venues` — opens Search on one of its switches.
  static String searchFor(String kind, {String? city}) => Uri(
        path: search,
        queryParameters: {'kind': kind, if (city != null) 'city': city},
      ).toString();
  static const String tickets = '/tickets';

  /// Everything booked, hosted, organized or supplied, by day.
  static const String calendar = '/calendar';

  /// Tickets, opened on the Requests switch.
  static const String ticketsRequests = '/tickets?segment=requests';
  static const String messages = '/messages';
  static String chat(String conversationId) =>
      '$messages/${Uri.encodeComponent(conversationId)}';
  static const String passport = '/passport';
  static const String profile = '/profile';

  /// Asked once after sign-in, before Home: use the device location?
  static const String location = '/location';

  /// Become a Foxer: the roles to apply for and where each stands.
  static const String roles = '/roles';

  /// Settings: location, account, sign out. Pushed from Passport.
  static const String settings = '/settings';

  /// A Foxer's profile. Takes the Foxer's catalog row as `extra`.
  static const String foxer = '/foxer';

  /// Match request to a Foxer. Takes the Foxer's catalog row as `extra`.
  static const String match = '/match';

  /// One venue in full, with Book now. Takes the venue row as `extra`.
  static const String venueDetail = '/venue';

  /// One event package: what is in it, customised and booked.
  static const String eventDetail = '/event';

  /// An event that its owner chose to publish.
  static const String scheduledEventDetail = '/scheduled-event';

  /// Venue booking flow, full screen. Takes the venue as `extra`.
  static const String book = '/book';

  /// Pushed from the app-bar bell.
  static const String notifications = '/notifications';
}
