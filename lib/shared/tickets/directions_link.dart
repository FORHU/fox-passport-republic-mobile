import 'package:flutter/foundation.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';

/// Where "Directions" sends the person: their phone's own maps app, which
/// does the turn-by-turn, traffic and voice. Pointed at the exact coordinates
/// when the booking has them, so the pin is right; otherwise a search for the
/// event and its town, which is the best that can be done without them.
///
/// Android gets a `geo:` link, which opens the maps app the person chose (or
/// asks which). iPhone has no `geo:`, so it opens Apple Maps. The web, and
/// anything else, opens Google Maps.
Uri directionsUri(
  Ticket ticket, {
  required TargetPlatform platform,
  required bool isWeb,
}) {
  if (!ticket.hasPin) return _searchUri(ticket);
  final lat = ticket.lat!;
  final lng = ticket.lng!;
  final spot = '$lat,$lng';
  if (!isWeb && platform == TargetPlatform.android) {
    // `q=lat,lng(Label)` drops a labelled pin; navigation starts from there.
    return Uri.parse(
      'geo:$spot?q=$spot(${Uri.encodeComponent(ticket.eventName)})',
    );
  }
  if (!isWeb && platform == TargetPlatform.iOS) {
    return Uri.https('maps.apple.com', '/', {
      'daddr': spot,
      'q': ticket.eventName,
    });
  }
  return googleDirectionsUri(ticket);
}

/// Google Maps directions to the coordinates, or the text search without them.
Uri googleDirectionsUri(Ticket ticket) {
  if (!ticket.hasPin) return _searchUri(ticket);
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${ticket.lat},${ticket.lng}',
  });
}

Uri _searchUri(Ticket ticket) {
  final query = [ticket.eventName, ticket.city]
      .whereType<String>()
      .where((p) => p.isNotEmpty)
      .join(', ');
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
}
