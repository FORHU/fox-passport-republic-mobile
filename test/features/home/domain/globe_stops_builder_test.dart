import 'package:flutter_template/features/home/domain/globe_stops_builder.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> event(
  String id,
  String name, {
  String? city,
  String? country,
  double? lat,
  double? lng,
  List<Map<String, dynamic>> venues = const [],
  String? image,
}) =>
    {
      'id': id,
      'name': name,
      'targetCity': city,
      'targetCountry': country,
      'lat': lat,
      'lng': lng,
      'templateVenues': [
        for (final v in venues) {'venue': v},
      ],
      'images': [
        if (image != null) {'url': image},
      ],
    };

void main() {
  group('buildGlobeStops', () {
    test('places an event by its own coordinates first', () {
      final stops = buildGlobeStops(
        events: [
          event('1', 'Debut', city: 'Manila', lat: 14.6, lng: 121),
        ],
        venues: const [],
      );

      expect(stops, hasLength(1));
      expect(stops.single.city, 'Manila');
      expect(stops.single.lat, 14.6);
      expect(stops.single.lng, 121.0);
      expect(stops.single.eventCount, 1);
      expect(stops.single.title, 'Debut');
    });

    test('falls back to the event venues, then to venues in that city', () {
      final stops = buildGlobeStops(
        events: [
          event(
            '1',
            'Wedding',
            city: 'Baguio',
            venues: [
              {'city': 'Baguio', 'lat': 16.41, 'lng': 120.59},
            ],
          ),
          event('2', 'Party', city: 'Davao'),
        ],
        venues: [
          {'city': 'Davao', 'lat': 7.19, 'lng': 125.45},
        ],
      );

      final byCity = {for (final s in stops) s.city: s};
      expect(byCity['Baguio']!.lat, 16.41);
      expect(byCity['Davao']!.lng, 125.45);
    });

    test('uses a known destination when nothing else locates the event', () {
      final stops = buildGlobeStops(
        events: [event('1', 'Beach', city: 'Boracay')],
        venues: const [],
      );

      expect(stops.single.city, 'Boracay');
      expect(stops.single.lat, closeTo(11.97, 0.01));
    });

    test('skips events it cannot place or name a city for', () {
      final stops = buildGlobeStops(
        events: [
          event('1', 'Nowhere', city: 'Atlantis'),
          event('2', 'No city'),
        ],
        venues: const [],
      );

      expect(stops, isEmpty);
    });

    test('pools one city and counts each event once', () {
      final stops = buildGlobeStops(
        events: [
          event('1', 'A', city: 'Manila', lat: 14.6, lng: 121),
          event('2', 'B', city: 'Manila', lat: 14.61, lng: 121.01),
          // The same event listed at two venue coordinates.
          event(
            '1',
            'A',
            city: 'Manila',
            lat: 14.6,
            lng: 121,
          ),
        ],
        venues: const [],
      );

      expect(stops, hasLength(1));
      expect(stops.single.eventCount, 2);
    });

    test('folds a nearby district into the busier city', () {
      final stops = buildGlobeStops(
        events: [
          event('1', 'A', city: 'Manila', lat: 14.5995, lng: 120.9842),
          event('2', 'B', city: 'Manila', lat: 14.5995, lng: 120.9842),
          event('3', 'C', city: 'Makati', lat: 14.5547, lng: 121.0244),
        ],
        venues: const [],
      );

      expect(stops, hasLength(1));
      expect(stops.single.city, 'Manila');
      expect(stops.single.eventCount, 3);
    });

    test('orders stops busiest first, whatever order the API used', () {
      final stops = buildGlobeStops(
        events: [
          event('1', 'Solo', city: 'Tokyo'),
          event('2', 'A', city: 'Cebu City'),
          event('3', 'B', city: 'Cebu City'),
        ],
        venues: const [],
      );

      expect(stops.map((s) => s.city).toList(), ['Cebu City', 'Tokyo']);
      expect(stops.first.eventCount, 2);
    });

    test('carries the headline event image onto the stop', () {
      final stops = buildGlobeStops(
        events: [
          event(
            '1',
            'Festival',
            city: 'Cebu City',
            image: 'https://example.com/a.jpg',
          ),
        ],
        venues: const [],
      );

      expect(stops.single.imageUrl, 'https://example.com/a.jpg');
    });

    test('ignores out-of-range coordinates', () {
      final stops = buildGlobeStops(
        events: [event('1', 'Bad', city: 'Manila', lat: 999, lng: 121)],
        venues: const [],
      );

      // Falls through to the known-destination table instead.
      expect(stops.single.lat, closeTo(14.6, 0.01));
    });
  });
}
