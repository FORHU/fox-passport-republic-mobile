/// Centralized API paths. Keep every endpoint here — never inline path strings
/// in data sources. Paths are relative to `AppConfig.instance.baseUrl`.
///
/// Parameterised paths are functions so callers can't forget an id segment.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth (Better Auth) ─────────────────────────────────────────────────
  static const String login = '/auth/sign-in/email';
  static const String register = '/auth/sign-up/email';
  static const String logout = '/auth/sign-out';
  // Email codes: Better Auth's emailOTP plugin.
  static const String verifyEmail = '/auth/email-otp/verify-email';
  static const String resendVerificationOtp =
      '/auth/email-otp/send-verification-otp';
  static const String forgotPassword = '/auth/email-otp/request-password-reset';
  static const String resetPassword = '/auth/email-otp/reset-password';

  // Social sign-in: a provider token minted on-device, verified by Better Auth.
  static const String socialSignIn = '/auth/sign-in/social';

  // ── Profile / users ─────────────────────────────────────────────────────
  static const String me = '/profile';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String users = '/users';

  /// The optional government-ID check (multipart on POST).
  static const String identityVerification = '/identity-verification';
  static const String identityMine = '/identity-verification/me';

  /// The people the signed-in user has blocked.
  static const String blocks = '/blocks';
  static String unblock(String userId) => '/blocks/$userId';
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

  // ── Following people
  static const String follows = '/follows';
  static String followTarget(String id) => '/follows/$id';
  static const String followRequests = '/follows/requests';
  static String followAccept(String id) => '/follows/$id/accept';
  static String followDecline(String id) => '/follows/$id/decline';
  static String followers(String id) => '/follows/$id/followers';
  static String following(String id) => '/follows/$id/following';
  static String followStatus(String id) => '/follows/$id/status';
  static String followCounts(String id) => '/follows/$id/counts';

  // ── Event waitlist (keyed by the event template) ────────────────────────
  static const String waitlist = '/waitlist';
  static String waitlistEntry(String id) => '/waitlist/$id';
  static String eventById(String id) => '/event-templates/$id';
  static const String assets = '/asset';
  static const String services = '/service';
  static String eventSubmit(String id) => '/event-templates/$id/submit';
  static String eventVenues(String id) => '/event-templates/$id/venues';
  static String eventVenue(String id, String venueId) =>
      '/event-templates/$id/venues/$venueId';
  static String eventAssets(String id) => '/event-templates/$id/assets';
  static String eventAsset(String id, String assetId) =>
      '/event-templates/$id/assets/$assetId';
  static String eventServices(String id) => '/event-templates/$id/services';
  static String eventService(String id, String serviceId) =>
      '/event-templates/$id/services/$serviceId';
  static const String assetsBrowse = '/asset/browse';
  static const String servicesBrowse = '/service/browse';

  // ── Venues ──────────────────────────────────────────────────────────────
  /// What suppliers are asked to confirm for other people's events.
  static const String providerRequests = '/event-transactions/provider';
  static String requestReview(String id) => '/event-transactions/$id/review';

  /// What the person has been paid and is owed, newest first.
  static const String venueAffiliationsMine = '/venue-affiliations/mine';

  /// The events (not templates) a person organizes, and the team of one venue
  /// or event: Organizers and Check-in Helpers.
  static const String organizerEvents = '/events';
  static const String organizerSearch = '/appointments/organizers';
  static String venueTeam(String id) =>
      '/venues/${Uri.encodeComponent(id)}/appointments';
  static String eventTeam(String id) =>
      '/events/${Uri.encodeComponent(id)}/appointments';

  // Bids on an event: service and gear applications, answered by the host.
  static const String bidOpenSlots = '/bids/open-slots';
  static const String bidServiceSubmit = '/bids/service';
  static const String bidAssetSubmit = '/bids/asset';
  static String serviceBidsForEvent(String eventId) =>
      '/bids/service/event/${Uri.encodeComponent(eventId)}';
  static String assetBidsForEvent(String eventId) =>
      '/bids/asset/event/${Uri.encodeComponent(eventId)}';
  static String bidAccept(String id, {required bool isService}) =>
      '/bids/${isService ? 'service' : 'asset'}/${Uri.encodeComponent(id)}/accept';
  static String bidReject(String id, {required bool isService}) =>
      '/bids/${isService ? 'service' : 'asset'}/${Uri.encodeComponent(id)}/reject';
  static const String venueAffiliationApply = '/venue-affiliations/apply';
  static const String venueAffiliationInvite = '/venue-affiliations/invite';
  static String venueAffiliationApprove(String id) =>
      '/venue-affiliations/$id/approve';
  static String venueAffiliationReject(String id) =>
      '/venue-affiliations/$id/reject';
  static String venueAffiliationCancel(String id) =>
      '/venue-affiliations/$id/cancel';
  static String venueAffiliation(String id) => '/venue-affiliations/$id';
  static const String payoutsMe = '/payouts/me';

  /// How far the person's payout account (Stripe) is set up.
  static const String stripeStatus = '/stripe-connect/status';

  /// Checks a guest in by the code on their ticket.
  static const String bookingCheckIn = '/bookings/check-in';
  static const String venues = '/venues';
  static const String venuesNear = '/venues/near';
  static const String venuesCatalog = '/venues/catalog';

  /// Where a new venue is created. The API keeps creation on its own path,
  /// `POST /venues/create`; `POST /venues` is not a route.
  static const String venueCreate = '/venues/create';

  static String venueById(String id) => '/venues/$id';
  static String venueUnavailableDates(String id) =>
      '/venues/$id/unavailable-dates';

  /// The days the venue's owner has closed. POST `{date}` to close one;
  /// DELETE [venueBlockedDate] (a `YYYY-MM-DD`) to open it again.
  static String venueBlockedDates(String id) => '/venues/$id/blocked-dates';
  static String venueBlockedDate(String id, String date) =>
      '/venues/$id/blocked-dates/$date';

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
  static const String bookingEditRequests = '/booking-edit-requests';
  static String bookingEditRequestWithdraw(String id) =>
      '/booking-edit-requests/$id/withdraw';

  static const String assetBookings = '/asset/bookings';
  static const String assetPricePreview = '/asset/bookings/price-preview';
  static String assetBookingById(String id) => '/asset/bookings/$id';
  static String assetBookingConfirm(String id) => '/asset/bookings/$id/confirm';

  static const String serviceBookings = '/service/bookings';
  static const String servicePricePreview = '/service/bookings/price-preview';
  static String serviceBookingById(String id) => '/service/bookings/$id';
  static String serviceBookingConfirm(String id) =>
      '/service/bookings/$id/confirm';

  // ── Republic feed ───────────────────────────────────────────────────────
  static const String feed = '/feed';
  static String feedReaction(String id) => '/feed/$id/reaction';
  static String feedReactions(String id) => '/feed/$id/reactions';
  static String feedComments(String id) => '/feed/$id/comments';
  static String feedComment(String id, String commentId) =>
      '/feed/$id/comments/$commentId';
  static String feedCommentLike(String id, String commentId) =>
      '/feed/$id/comments/$commentId/like';
  static String feedPost(String id) => '/feed/$id';
  static String feedSave(String id) => '/feed/$id/save';
  static String feedRepost(String id) => '/feed/$id/repost';
  static String feedPollVote(String id) => '/feed/$id/poll/vote';
  static String feedHide(String id) => '/feed/$id/hide';
  static const String feedSaved = '/feed/saved';
  static const String feedMentionSearch = '/feed/mentions/search';
  static const String reports = '/reports';

  // ── Promotions ──────────────────────────────────────────────────────────
  static const String promotionsMine = '/promotions/mine';
  static String promotionMine(String id) => '$promotionsMine/$id';

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
  static const String venueBoundaries = '/venues/boundaries';
  static const String cancellationPolicies = '/cancellation-policies';
  static const String fxRates = '/fx/rates';
  static String conversationMute(String id) => '/conversations/$id/mute';
  static String conversationPin(String id) => '/conversations/$id/pin';
  static String conversationMessage(String id, String messageId) =>
      '/conversations/$id/messages/$messageId';
  static String conversationReaction(String id, String messageId) =>
      '/conversations/$id/messages/$messageId/reaction';
}
