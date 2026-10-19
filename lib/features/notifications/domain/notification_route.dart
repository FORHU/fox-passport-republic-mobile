import 'package:flutter_template/routes/route_names.dart';

/// The screen in this app for a notification's web [link], or null when the
/// app has no such screen (a host page, an invoice, another user's profile).
///
/// The API sends web paths, so only the ones that have a mobile screen map:
///
/// | Web link | Mobile |
/// |---|---|
/// | `/booking/<id>`, `/bookings/<id>`, `/booking/fulfillment/...` | Tickets |
/// | `/messages?conversationId=<id>` | that chat |
/// | `/messages`, `/messages?userId=<id>` | Messages |
/// | `/user/passport` | Passport |
/// | `/calendar` | Calendar |
String? notificationRoute(String? link) {
  if (link == null || link.isEmpty) return null;
  final uri = Uri.tryParse(link);
  if (uri == null) return null;
  final segments = uri.pathSegments;
  if (segments.isEmpty) return null;

  switch (segments.first) {
    case 'booking' || 'bookings':
      return RouteNames.tickets;
    case 'messages':
      final conversationId = uri.queryParameters['conversationId'];
      return conversationId == null || conversationId.isEmpty
          ? RouteNames.messages
          : RouteNames.chat(conversationId);
    case 'user':
      return segments.length == 2 && segments[1] == 'passport'
          ? RouteNames.passport
          : null;
    case 'calendar':
      return RouteNames.calendar;
    default:
      return null;
  }
}
