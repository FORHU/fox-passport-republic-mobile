import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_test/flutter_test.dart';

const GeoPoint _manila = (lat: 14.5995, lng: 120.9842);

VenueDraft _complete() => const VenueDraft(
      name: 'Sky Hall',
      category: 'indoor',
      description: 'A hall',
      capacity: 100,
      address: '1 Main St',
      city: 'Manila',
      country: 'Philippines',
      center: _manila,
      photos: [VenuePhoto(fileId: 'f1', url: 'https://x.test/a.png')],
      price: 5000,
    );

void main() {
  group('service area', () {
    test('is a closed ring of [lng, lat] points around the pin', () {
      final ring = circlePolygon(_manila, 300);

      expect(ring.first, ring.last);
      expect(ring, hasLength(25));
      // lng comes first: Manila is near 121 east, 14.6 north.
      expect(ring.first[0], closeTo(120.98, 0.05));
      expect(ring.first[1], closeTo(14.6, 0.05));
    });

    test('can be read back as the same pin and radius', () {
      final circle = circleOf(circlePolygon(_manila, 450));

      expect(circle, isNotNull);
      expect(circle!.radiusMeters, closeTo(450, 10));
      expect(circle.center.lat, closeTo(_manila.lat, 0.0005));
      expect(circle.center.lng, closeTo(_manila.lng, 0.0005));
    });

    test('a shape drawn on the web is not mistaken for a circle', () {
      final square = <List<double>>[
        [120.0, 14.0],
        [120.01, 14.0],
        [120.01, 14.05],
        [120.0, 14.05],
        [120.0, 14.0],
      ];

      expect(circleOf(square), isNull);
    });

    test('overlap is found for rings that touch, not for ones apart', () {
      final here = circlePolygon(_manila, 300);
      final next = circlePolygon((lat: 14.6010, lng: 120.9842), 300);
      final far = circlePolygon((lat: 14.7, lng: 121.1), 300);

      expect(ringsOverlap(here, next), isTrue);
      expect(ringsOverlap(here, far), isFalse);
    });

    test('a ring inside another counts as overlapping', () {
      expect(
        ringsOverlap(
          circlePolygon(_manila, 1000),
          circlePolygon(_manila, 100),
        ),
        isTrue,
      );
    });
  });

  group('VenueDraft', () {
    test('lists what is missing, in the order of the steps', () {
      expect(
        const VenueDraft().missing,
        [
          'name',
          'category',
          'description',
          'capacity',
          'address',
          'location',
          'photos',
          'price',
        ],
      );
      expect(_complete().missing, isEmpty);
      expect(_complete().readyToSubmit, isTrue);
    });

    test('sends photo file ids, not urls, and the boundary as a ring', () {
      final json = _complete().toJson(status: 'pending');

      expect(json['imgIds'], ['f1']);
      expect(json['status'], 'pending');
      expect((json['boundary'] as List).length, 25);
      expect(json['name'], 'Sky Hall');
    });

    test('leaves status out when saving a live venue', () {
      expect(_complete().toJson().containsKey('status'), isFalse);
    });

    test('leaves the state out when blank', () {
      expect(_complete().toJson().containsKey('state'), isFalse);
      expect(
        _complete().copyWith(state: 'NCR').toJson()['state'],
        'NCR',
      );
    });
  });
}
