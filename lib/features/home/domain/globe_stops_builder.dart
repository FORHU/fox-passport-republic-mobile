import 'dart:math' as math;

import 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart';

/// Where events are happening, as pins for the home globe.
///
/// A port of the web landing's `buildEventLocations` + `mergeLocationsByCity`
/// (`features/landing/journey/data.ts`): every event is placed by the best
/// coordinates available, points of one city are pooled, and cities within half
/// a degree of a busier one are folded into it — so Makati and Taguig are
/// Manila, and a city with three venues gets one card, not three.
///
/// Pure, so it is testable without the network.
List<GlobeStop> buildGlobeStops({
  required List<Map<String, dynamic>> events,
  required List<Map<String, dynamic>> venues,
}) {
  final points = <_Point>[];

  for (final event in events) {
    final id = (event['id'] ?? '').toString();
    final templateVenues = _venuesOf(event);
    final city = _text(event['targetCity']) ??
        _text(
          templateVenues
              .map((v) => _text(v['city']))
              .firstWhere((c) => c != null, orElse: () => null),
        );
    if (id.isEmpty || city == null) continue;

    final cityKey = _norm(city);
    final country = _text(event['targetCountry']);
    final coords = <({double lat, double lng})>[];

    // 1. The event's own coordinates.
    final own = _coord(event['lat'], event['lng']);
    if (own != null) coords.add(own);

    // 2. The venues attached to the event, in the same city.
    if (coords.isEmpty) {
      for (final v in templateVenues) {
        if (_norm(_text(v['city']) ?? '') != cityKey) continue;
        final c = _coord(v['lat'], v['lng']);
        if (c != null) coords.add(c);
      }
    }

    // 3. Any known venue in that city.
    if (coords.isEmpty) {
      for (final v in venues) {
        if (_norm(_text(v['city']) ?? '') != cityKey) continue;
        final c = _coord(v['lat'], v['lng']);
        if (c != null) coords.add(c);
      }
    }

    // 4. A well-known destination.
    if (coords.isEmpty) {
      final known = _knownCities[cityKey];
      if (known != null) coords.add(known);
    }

    for (final c in coords) {
      points.add(
        _Point(
          city: city,
          country: country,
          lat: c.lat,
          lng: c.lng,
          event: _EventRef(
            id: id,
            name: _text(event['name']) ?? city,
            imageUrl: _firstImage(event),
          ),
        ),
      );
    }
  }

  return _merge(_pool(points));
}

// ── Pooling / merging ────────────────────────────────────────────────────

/// One place and every event around it.
class _Place {
  _Place(this.city, this.country, this.lat, this.lng, this.events);

  final String city;
  final String? country;
  final double lat;
  final double lng;
  final List<_EventRef> events;
}

class _EventRef {
  const _EventRef({required this.id, required this.name, this.imageUrl});

  final String id;
  final String name;
  final String? imageUrl;
}

class _Point {
  const _Point({
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
    required this.event,
  });

  final String city;
  final String? country;
  final double lat;
  final double lng;
  final _EventRef event;
}

/// Points sharing a city are pooled into one place; the pin sits at the point
/// holding the most events (ties go to the first), so it stays put.
List<_Place> _pool(List<_Point> points) {
  final byCoord = <String, _Place>{};
  for (final p in points) {
    final key =
        '${_norm(p.city)}|${_norm(p.country ?? '')}|${p.lat.toStringAsFixed(3)}|${p.lng.toStringAsFixed(3)}';
    final place = byCoord.putIfAbsent(
        key, () => _Place(p.city, p.country, p.lat, p.lng, []));
    if (!place.events.any((e) => e.id == p.event.id)) place.events.add(p.event);
  }

  final byCity = <String, List<_Place>>{};
  for (final place in byCoord.values) {
    final id = '${_norm(place.city)}|${_norm(place.country ?? '')}';
    byCity.putIfAbsent(id, () => []).add(place);
  }
  return byCity.values.map(_poolGroup).toList();
}

_Place _poolGroup(List<_Place> group) {
  if (group.length == 1) return group.first;
  final seen = <String>{};
  final events = [
    for (final p in group)
      for (final e in p.events)
        if (seen.add(e.id)) e,
  ];
  var pin = group.first;
  for (final p in group) {
    if (p.events.length > pin.events.length) pin = p;
  }
  return _Place(pin.city, pin.country, pin.lat, pin.lng, events);
}

const double _nearbyDegrees = 0.5;

bool _isNearby(_Place a, _Place b) {
  final cos = math.cos(((a.lat + b.lat) / 2) * math.pi / 180);
  return math.sqrt(
        math.pow(a.lat - b.lat, 2) + math.pow((a.lng - b.lng) * cos, 2),
      ) <
      _nearbyDegrees;
}

List<GlobeStop> _merge(List<_Place> pooled) {
  // Busiest first, so a cluster is anchored on its biggest member and the
  // result doesn't depend on the order the API returned things in.
  pooled.sort((a, b) {
    final byCount = b.events.length.compareTo(a.events.length);
    return byCount != 0 ? byCount : a.city.compareTo(b.city);
  });

  final taken = <_Place>{};
  final stops = <GlobeStop>[];
  for (final anchor in pooled) {
    if (taken.contains(anchor)) continue;
    final cluster = [
      for (final p in pooled)
        if (!taken.contains(p) &&
            (identical(p, anchor) || _isNearby(anchor, p)))
          p,
    ];
    taken.addAll(cluster);
    final merged = _poolGroup(cluster);
    final headline = merged.events.first;
    stops.add(
      GlobeStop(
        city: merged.city,
        lat: merged.lat,
        lng: merged.lng,
        eventCount: merged.events.length,
        title: headline.name,
        imageUrl: headline.imageUrl,
      ),
    );
  }
  return stops;
}

// ── Helpers ──────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _venuesOf(Map<String, dynamic> event) {
  final raw = event['templateVenues'];
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map && item['venue'] is Map)
        (item['venue'] as Map).cast<String, dynamic>(),
  ];
}

String? _firstImage(Map<String, dynamic> event) {
  final images = event['images'];
  if (images is List && images.isNotEmpty && images.first is Map) {
    return _text((images.first as Map)['url']);
  }
  return null;
}

String? _text(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

/// Lower-cased, accent-free, punctuation-free, for comparing place names.
String _norm(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();

({double lat, double lng})? _coord(Object? lat, Object? lng) {
  final la = lat is num ? lat.toDouble() : double.tryParse('$lat');
  final lo = lng is num ? lng.toDouble() : double.tryParse('$lng');
  if (la == null || lo == null) return null;
  if (!la.isFinite || !lo.isFinite) return null;
  if (la < -90 || la > 90 || lo < -180 || lo > 180) return null;
  return (lat: la, lng: lo);
}

/// Where a city is when neither the event nor any venue says. Mirrors the web
/// app's `DESTINATIONS`, plus the Philippine destinations its seeded events use.
const Map<String, ({double lat, double lng})> _knownCities = {
  'manila': (lat: 14.5995, lng: 120.9842),
  'cebu city': (lat: 10.3157, lng: 123.8854),
  'cebu': (lat: 10.3157, lng: 123.8854),
  'davao city': (lat: 7.1907, lng: 125.4553),
  'baguio': (lat: 16.4023, lng: 120.5960),
  'baguio city': (lat: 16.4023, lng: 120.5960),
  'boracay': (lat: 11.9674, lng: 121.9248),
  'tokyo': (lat: 35.6762, lng: 139.6503),
  'paris': (lat: 48.8566, lng: 2.3522),
  'male': (lat: 4.1755, lng: 73.5093),
  'washington d c': (lat: 38.9072, lng: -77.0369),
};
