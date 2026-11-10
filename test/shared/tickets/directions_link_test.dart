import 'package:flutter/foundation.dart';
import 'package:flutter_template/shared/tickets/directions_link.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_test/flutter_test.dart';

Ticket _ticket({double? lat, double? lng, String? city = 'Pasig'}) => Ticket(
      id: 'b1',
      eventName: 'All-In-One Social Night',
      startAt: DateTime(2026, 11, 11, 18),
      endAt: DateTime(2026, 11, 11, 23),
      status: 'confirmed',
      city: city,
      lat: lat,
      lng: lng,
    );

void main() {
  group('with coordinates', () {
    final ticket = _ticket(lat: 14.5764, lng: 121.0851);

    test('Android opens a geo link, so the phone offers its maps apps', () {
      final uri = directionsUri(
        ticket,
        platform: TargetPlatform.android,
        isWeb: false,
      );
      expect(uri.scheme, 'geo');
      expect(
        uri.toString(),
        'geo:14.5764,121.0851?q=14.5764,121.0851(All-In-One%20Social%20Night)',
      );
    });

    test('iPhone opens Apple Maps at the spot', () {
      final uri = directionsUri(
        ticket,
        platform: TargetPlatform.iOS,
        isWeb: false,
      );
      expect(uri.host, 'maps.apple.com');
      expect(uri.queryParameters['daddr'], '14.5764,121.0851');
    });

    test('the web opens Google Maps directions to the spot', () {
      final uri = directionsUri(
        ticket,
        platform: TargetPlatform.android,
        isWeb: true,
      );
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '14.5764,121.0851');
    });

    test('desktop falls back to Google Maps too', () {
      final uri = directionsUri(
        ticket,
        platform: TargetPlatform.windows,
        isWeb: false,
      );
      expect(uri.path, '/maps/dir/');
    });

    test('the fallback link always goes to the spot', () {
      expect(
        googleDirectionsUri(ticket).queryParameters['destination'],
        '14.5764,121.0851',
      );
    });
  });

  group('without coordinates', () {
    test('every platform searches for the event and its town', () {
      final ticket = _ticket();
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        final uri = directionsUri(ticket, platform: platform, isWeb: false);
        expect(uri.host, 'www.google.com', reason: '$platform');
        expect(uri.path, '/maps/search/');
        expect(
          uri.queryParameters['query'],
          'All-In-One Social Night, Pasig',
        );
      }
    });

    test('one coordinate alone is not a pin', () {
      final ticket = _ticket(lat: 14.5);
      expect(ticket.hasPin, isFalse);
      expect(
        directionsUri(ticket, platform: TargetPlatform.android, isWeb: false)
            .path,
        '/maps/search/',
      );
    });

    test('no town leaves just the name', () {
      final uri = directionsUri(
        _ticket(city: null),
        platform: TargetPlatform.android,
        isWeb: false,
      );
      expect(uri.queryParameters['query'], 'All-In-One Social Night');
    });
  });

  group('the Ticket carries them', () {
    test("read from the booking's event, and kept in the saved copy", () {
      final ticket = Ticket.fromBooking(const {
        'id': 'b1',
        'status': 'confirmed',
        'startAt': '2026-11-11T10:00:00.000Z',
        'endAt': '2026-11-11T15:00:00.000Z',
        'event': <String, Object>{'name': 'Night', 'lat': 14.5764, 'lng': 121},
      });
      expect(ticket.lat, 14.5764);
      expect(ticket.lng, 121.0);
      expect(ticket.hasPin, isTrue);

      final saved = Ticket.fromCache(ticket.toCache(), DateTime(2026, 11, 10));
      expect(saved.lat, 14.5764);
      expect(saved.lng, 121.0);
    });

    test('an older API with none gives no pin', () {
      final ticket = Ticket.fromBooking(const {
        'id': 'b1',
        'status': 'confirmed',
        'event': <String, Object>{'name': 'Night'},
      });
      expect(ticket.hasPin, isFalse);
    });
  });
}
