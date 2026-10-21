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
  static String searchFor(
    String kind, {
    String? city,
    int? minCapacity,
    DateTime? date,
  }) =>
      Uri(
        path: search,
        queryParameters: {
          'kind': kind,
          if (city != null) 'city': city,
          if (minCapacity != null) 'capacity': '$minCapacity',
          if (date != null) 'date': date.toIso8601String().split('T').first,
        },
      ).toString();

  /// Planning by occasion: `/occasion/wedding`.
  static String occasion(String name) =>
      '/occasion/${Uri.encodeComponent(name)}';

  /// Every category, grouped: "Everything you can book".
  static const String allCategories = '/categories';
  static const String tickets = '/tickets';

  /// Root route of each bottom-nav tab, left to right. The shell branches in
  /// `app_routes.dart` and the tab bar in `main_layout.dart` both follow this
  /// order, because the tab index is the branch index.
  static const List<String> shellTabs = [
    home,
    search,
    tickets,
    messages,
    passport,
  ];

  /// Tickets, opened on the Requests switch.
  static const String ticketsRequests = '/tickets?segment=requests';

  /// Bookings, opened on the Calendar switch: everything booked, hosted,
  /// organized or supplied, by day.
  static const String ticketsCalendar = '/tickets?segment=calendar';
  static const String messages = '/messages';
  static String chat(String conversationId) =>
      '$messages/${Uri.encodeComponent(conversationId)}';
  static const String passport = '/passport';
  static const String profile = '/profile';

  /// Edit the profile: photo, name, username, phone, privacy. Pushed from
  /// Profile and Settings.
  static const String profileEdit = '/profile/edit';

  /// Asked once after sign-in, before Home: use the device location?
  static const String location = '/location';

  /// Become a Foxer: the roles to apply for and where each stands.
  static const String roles = '/roles';

  /// Settings: location, account, sign out. Pushed from Passport.
  static const String settings = '/settings';

  /// Change the password. Pushed from Settings.
  static const String changePassword = '/settings/password';

  /// The people you blocked, with a way to unblock. Pushed from Settings.
  static const String blockedUsers = '/settings/blocked';

  /// A Foxer's profile. Takes the Foxer's catalog row as `extra`.
  static const String foxer = '/foxer';

  /// Match request to a Foxer. Takes the Foxer's catalog row as `extra`.
  static const String match = '/match';

  /// The Republic: the community feed.
  static const String republic = '/republic';

  /// The Venue space, for someone who holds the VenueFoxer role. Five tabs:
  /// Overview, Venues, Calendar, Earnings and More.
  static const String spaceVenue = '/space/venue';
  static const String spaceVenueVenues = '/space/venue/venues';

  /// One of their venues: what they can do with it.
  static String spaceVenueHub(String venueId) => '$spaceVenueVenues/$venueId';
  static const String spaceVenueCalendar = '/space/venue/calendar';
  static const String spaceVenueEarnings = '/space/venue/earnings';
  static const String spaceVenueMore = '/space/venue/more';

  /// Adding or editing a venue: full screen, outside the tabs, so it can be
  /// pushed from the Venues tab and from a venue's hub alike.
  static const String spaceVenueStudio = '/space/venue/studio';
  static String spaceVenueStudioEdit(String venueId) =>
      '$spaceVenueStudio/$venueId';

  /// Opened from More: requests for their venues, check-in and messages.
  static const String spaceVenueRequests = '/space/venue/more/requests';
  static const String spaceVenueCheckIn = '/space/venue/more/check-in';
  static const String spaceVenueMessages = '/space/venue/more/messages';

  /// The Event space, for an EventFoxer: their events, check-in and messages.
  static const String spaceEvent = '/space/event';
  static const String spaceEventCheckIn = '/space/event/check-in';
  static const String spaceEventMessages = '/space/event/messages';

  /// One piece of gear or one service, with its booking. Takes the row as
  /// `extra`.
  static const String itemBooking = '/book/item';

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
