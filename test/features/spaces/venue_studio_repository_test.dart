import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const GeoPoint _pin = (lat: 14.5995, lng: 120.9842);

const _draft = VenueDraft(
  name: 'Sky Hall',
  category: 'indoor',
  description: 'A hall',
  capacity: 100,
  address: '1 Main St',
  city: 'Manila',
  country: 'Philippines',
  center: _pin,
  photos: [VenuePhoto(fileId: 'f1', url: 'https://x.test/a.png')],
  price: 5000,
);

void main() {
  late _MockApi api;
  late SpacesRepository repo;

  setUp(() {
    api = _MockApi();
    repo = SpacesRepository(api, 'u1');
  });

  group('creating a venue', () {
    test('saves a draft, or sends it for review', () async {
      when(() => api.post('/venues/create', any())).thenAnswer(
        (_) async => {
          'venue': {'id': 'v9'},
        },
      );

      expect(await repo.createVenue(_draft, submit: false), 'v9');
      await repo.createVenue(_draft, submit: true);

      final bodies = verify(() => api.post('/venues/create', captureAny()))
          .captured
          .cast<Map<String, dynamic>>();
      expect(bodies[0]['status'], 'draft');
      expect(bodies[1]['status'], 'pending');
    });

    test("goes to the API's create path, not the collection", () async {
      when(() => api.post('/venues/create', any())).thenAnswer(
        (_) async => {
          'venue': {'id': 'v9'},
        },
      );

      await repo.createVenue(_draft, submit: false);

      verify(() => api.post('/venues/create', any())).called(1);
      verifyNever(() => api.post('/venues', any()));
    });

    test('fails when the API gives no id back', () async {
      when(() => api.post('/venues/create', any())).thenAnswer((_) async => {});

      expect(
        () => repo.createVenue(_draft, submit: false),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('saving changes', () {
    setUp(() {
      when(() => api.put('/venues/v1', any())).thenAnswer((_) async => {});
    });

    test('a live venue is sent without a status, so it stays live', () async {
      await repo.updateVenue('v1', _draft, live: true, submit: true);

      final body = verify(() => api.put('/venues/v1', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body.containsKey('status'), isFalse);
    });

    test('a venue not yet live goes back to draft or on to review', () async {
      await repo.updateVenue('v1', _draft, live: false, submit: false);
      await repo.updateVenue('v1', _draft, live: false, submit: true);

      final bodies = verify(() => api.put('/venues/v1', captureAny()))
          .captured
          .cast<Map<String, dynamic>>();
      expect(bodies.map((b) => b['status']), ['draft', 'pending']);
    });
  });

  group('photos', () {
    final photo = PickedPhoto(bytes: Uint8List.fromList([1, 2]), name: 'a.jpg');

    test('come back as the file id the venue needs, with a url', () async {
      when(() => api.post('/files/upload-direct', any())).thenAnswer(
        (_) async => {'fileId': 'f7', 'url': 'https://x.test/7.jpg'},
      );

      final uploaded = await repo.uploadVenuePhoto(photo);

      expect(uploaded.fileId, 'f7');
      expect(uploaded.url, 'https://x.test/7.jpg');
      final form = verify(() => api.post('/files/upload-direct', captureAny()))
          .captured
          .single;
      expect(form, isA<FormData>());
    });

    test('are refused when the upload has no file id', () async {
      when(() => api.post('/files/upload-direct', any())).thenAnswer(
        (_) async => {'url': 'https://x.test/7.jpg'},
      );

      expect(
        () => repo.uploadVenuePhoto(photo),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('reading a venue to edit', () {
    test('fills the draft from the saved venue', () async {
      final ring = circlePolygon(_pin, 450);
      when(() => api.get('/venues/v1')).thenAnswer(
        (_) async => {
          'venue': {
            'id': 'v1',
            'status': 'available',
            'name': 'Sky Hall',
            'category': 'indoor',
            'description': 'A hall',
            'capacity': 100,
            'address': '1 Main St',
            'city': 'Manila',
            'country': 'Philippines',
            'price': '5000',
            'billingRate': 'hourly',
            'boundary': ring,
            'amenities': ['wifi'],
            'images': [
              {'id': 'f1', 'url': 'https://x.test/a.png'},
            ],
          },
        },
      );

      final detail = await repo.venueDetail('v1');

      expect(detail.isLive, isTrue);
      expect(detail.draft.name, 'Sky Hall');
      expect(detail.draft.price, 5000);
      expect(detail.draft.billingRate, 'hourly');
      expect(detail.draft.amenities, ['wifi']);
      expect(detail.draft.photos.single.fileId, 'f1');
      expect(detail.draft.radiusMeters, closeTo(450, 10));
      expect(detail.draft.center!.lat, closeTo(_pin.lat, 0.001));
      expect(detail.draft.readyToSubmit, isTrue);
    });

    test('a shape drawn on the web keeps its pin from lat and lng', () async {
      when(() => api.get('/venues/v1')).thenAnswer(
        (_) async => {
          'id': 'v1',
          'status': 'draft',
          'lat': 14.6,
          'lng': 121.0,
          'boundary': [
            [120.9, 14.5],
            [121.1, 14.5],
            [121.1, 14.7],
            [120.9, 14.5],
          ],
        },
      );

      final detail = await repo.venueDetail('v1');

      expect(detail.isLive, isFalse);
      expect(detail.draft.center, (lat: 14.6, lng: 121.0));
    });
  });

  group('around the area', () {
    test('lists neighbours and skips ones without a usable shape', () async {
      when(
        () => api.get(
          '/venues/boundaries',
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async => {
          'boundaries': [
            {
              'id': 'n1',
              'name': 'Next Door',
              'boundary': circlePolygon(_pin, 200),
            },
            {'id': 'n2', 'name': 'No shape'},
          ],
        },
      );

      final neighbours = await repo.neighbourBoundaries(excludeId: 'v1');

      expect(neighbours.map((n) => n.id), ['n1']);
      verify(
        () => api.get('/venues/boundaries', query: {'excludeId': 'v1'}),
      ).called(1);
    });

    test('lists cancellation policies', () async {
      when(() => api.get('/cancellation-policies')).thenAnswer(
        (_) async => {
          'data': [
            {'id': 'p1', 'name': 'Flexible'},
            {'name': 'broken'},
          ],
        },
      );

      final policies = await repo.cancellationPolicies();

      expect(policies.map((p) => p.name), ['Flexible']);
    });
  });
}
