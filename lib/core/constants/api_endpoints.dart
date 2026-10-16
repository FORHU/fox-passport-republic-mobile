/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
///
/// Parameterised paths are functions so callers can't forget an id segment.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth (Better Auth) ─────────────────────────────────────────────────
  static const String login = '/auth/sign-in/email';
  static const String register = '/auth/sign-up/email';
  static const String refresh = '/auth/refresh-token';
  static const String logout = '/auth/sign-out';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerificationOtp = '/auth/resend-verification-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Social sign-in. `*Mobile` take a token the app got on-device; the plain
  // path starts the browser redirect flow and `*Exchange` redeems its code.
  static const String googleMobile = '/auth/google/mobile';
  static const String facebookMobile = '/auth/facebook/mobile';
  static const String googleStart = '/auth/google';
  static const String facebookStart = '/auth/facebook';
  static const String googleExchange = '/auth/google/exchange';
  static const String facebookExchange = '/auth/facebook/exchange';

  // ── Profile / users ─────────────────────────────────────────────────────
  static const String me = '/profile';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String users = '/users';
  static const String foxers = '/users/foxers';
  static String foxerById(String id) => '/users/foxers/$id';
  static const String matches = '/matches';
  static const String calendar = '/calendar';
  static const String categories = '/categories';
  static const String matchesMine = '/matches/my';
  static String publicProfile(String idOrUsername) =>
      '/users/profile/$idOrUsername';

  // ── Roles & locations (onboarding) ──────────────────────────────────────
  static const String roleRequestsMine = '/role-requests/my';
  static const String locationCountries = '/locations/countries';
  static String locationStates(String countryCode) =>
      '/locations/countries/$countryCode/states';
  static String locationCities(String countryCode) =>
      '/locations/countries/$countryCode/cities';

  // ── Browse ──────────────────────────────────────────────────────────────
  static const String events = '/event-templates';
  static const String eventsBrowse = '/event-templates/browse';
  static const String publicEventsBrowse = '/events/browse';
  static String eventPublicVisibility(String id) =>
      '/events/${Uri.encodeComponent(id)}/public-visibility';
  static const String eventRecommendations = '/event-templates/recommendations';
  static String eventBrowseById(String id) => '/event-templates/browse/$id';
  static String eventById(String id) => '/event-templates/$id';
  static const String assetsBrowse = '/asset/browse';
  static const String servicesBrowse = '/service/browse';

  // ── Venues ──────────────────────────────────────────────────────────────
  static const String venues = '/venues';
  static const String venuesNear = '/venues/near';
  static const String venuesCatalog = '/venues/catalog';
  static String venueById(String id) => '/venues/$id';
  static String venueUnavailableDates(String id) =>
      '/venues/$id/unavailable-dates';

  // ── Bookings ────────────────────────────────────────────────────────────
  static const String bookingDraft = '/bookings/draft';
  static const String bookingFromTemplate = '/bookings/from-template';
  static const String bookingsUpcoming = '/bookings/upcoming';
  static const String bookingsAvailability = '/bookings/availability';
  static const String venuePricePreview = '/bookings/venue-price-preview';
  static String bookingsOfUser(String userId) => '/bookings/user/$userId';
  static String bookingById(String id) => '/bookings/$id';
  static String bookingAttendees(String id) => '/bookings/$id/attendees';
  static String bookingConfirm(String id) => '/bookings/$id/confirm';
  static String bookingCancelCheck(String id) => '/bookings/$id/cancel/check';
  static String bookingCancel(String id) => '/bookings/$id/cancel';

  static const String assetBookings = '/asset/bookings';
  static const String assetPricePreview = '/asset/bookings/price-preview';
  static String assetBookingById(String id) => '/asset/bookings/$id';
  static String assetBookingConfirm(String id) => '/asset/bookings/$id/confirm';

  static const String serviceBookings = '/service/bookings';
  static const String servicePricePreview = '/service/bookings/price-preview';
  static String serviceBookingById(String id) => '/service/bookings/$id';
  static String serviceBookingConfirm(String id) =>
      '/service/bookings/$id/confirm';

  // ── Reviews ─────────────────────────────────────────────────────────────
  static String reviewsOfListing(String id) => '/reviews/listing/$id';
  static const String reviewsCreate = '/reviews/create';

  // ── Payments ────────────────────────────────────────────────────────────
  static const String createPaymentIntent = '/payments/create-intent';

  // ── Passport ────────────────────────────────────────────────────────────
  static const String passportMe = '/passport/me';
  static const String passportBadges = '/passport/badges';
  static const String passportLeaderboard = '/passport/leaderboard';
  static String passportByUser(String userId) => '/passport/$userId';

  // ── Favorites ───────────────────────────────────────────────────────────
  static const String favorites = '/favorites';
  static String favoritesByUser(String userId) => '/favorites/user/$userId';
  static const String favoriteAdd = '/favorites/add';
  static const String favoriteRemoveByListing = '/favorites/remove/listing';

  // ── Notifications ───────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // ── Messages ───────────────────────────────────────────────────────────
  static const String conversations = '/conversations';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';
  static String conversationRead(String id) => '/conversations/$id/read';
  static String conversationAccept(String id) => '/conversations/$id/accept';
  static String conversationDecline(String id) => '/conversations/$id/decline';
  static const String conversationsInbox = '/conversations/inbox';
  static const String socketTicket = '/auth/socket-ticket';
  static const String uploadFile = '/files/upload-direct';
  static const String fxRates = '/fx/rates';
  static String conversationMute(String id) => '/conversations/$id/mute';
  static String conversationPin(String id) => '/conversations/$id/pin';
  static String conversationMessage(String id, String messageId) =>
      '/conversations/$id/messages/$messageId';
  static String conversationReaction(String id, String messageId) =>
      '/conversations/$id/messages/$messageId/reaction';
}
