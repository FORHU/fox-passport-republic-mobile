import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, Object?> _row(
  String id, {
  String status = 'pending_provider_confirmation',
  String venue = 'Sky Hall',
}) =>
    {
      'id': id,
      'status': status,
      'agreedPrice': 25000,
      'confirmationDeadline': '2099-12-20T10:00:00.000Z',
      'event': {
        'name': 'Ada Birthday',
        'startAt': '2099-12-25T10:00:00.000Z',
        'client': {'name': 'Ada'},
      },
      'venue': {
        'name': venue,
        'images': [
          {'url': 'https://x.test/a.png'},
        ],
      },
    };

void main() {
  group('AppSpace', () {
    test('Citizen is always there; Venue and Event need their role', () {
      expect(AppSpace.availableTo(const []), [AppSpace.citizen]);
      expect(
        AppSpace.availableTo(const ['venueFoxer']),
        [AppSpace.citizen, AppSpace.venue],
      );
      expect(
        AppSpace.availableTo(const ['eventFoxer', 'venueFoxer', 'gearFoxer']),
        [AppSpace.citizen, AppSpace.venue, AppSpace.event],
      );
    });

    test('other roles open no space of their own yet', () {
      expect(
        AppSpace.availableTo(const ['gearFoxer', 'investor', 'organizer']),
        [AppSpace.citizen],
      );
    });

    test('knows which space a location belongs to', () {
      expect(AppSpace.forPath('/space/venue'), AppSpace.venue);
      expect(AppSpace.forPath('/space/venue/check-in'), AppSpace.venue);
      expect(AppSpace.forPath('/space/event'), AppSpace.event);
      expect(AppSpace.forPath('/'), isNull);
      expect(AppSpace.forPath('/passport'), isNull);
      // A name that only starts the same is not the space.
      expect(AppSpace.forPath('/space/venues'), isNull);
    });

    test('a saved name comes back as the space, Citizen when unknown', () {
      expect(AppSpace.fromName('venue'), AppSpace.venue);
      expect(AppSpace.fromName('nonsense'), AppSpace.citizen);
      expect(AppSpace.fromName(null), AppSpace.citizen);
    });

    test('the roots are the route names the router uses', () {
      expect(AppSpace.venue.root, RouteNames.spaceVenue);
      expect(AppSpace.event.root, RouteNames.spaceEvent);
      expect(AppSpace.citizen.root, RouteNames.home);
    });
  });

  group('VenueRequest', () {
    test('reads the venue, the event, who asked and when to reply by', () {
      final r = VenueRequest.tryParse(_row('r1'))!;

      expect(r.venueName, 'Sky Hall');
      expect(r.eventName, 'Ada Birthday');
      expect(r.clientName, 'Ada');
      expect(r.price, 25000);
      expect(r.imageUrl, 'https://x.test/a.png');
      expect(r.status, RequestStatus.awaitingYou);
      expect(r.needsReply, isTrue);
      expect(r.startAt, isNotNull);
      expect(r.replyBy, isNotNull);
    });

    test('knows each status word', () {
      expect(RequestStatus.parse('pending'), RequestStatus.pending);
      expect(RequestStatus.parse('approved'), RequestStatus.approved);
      expect(RequestStatus.parse('rejected'), RequestStatus.rejected);
      expect(RequestStatus.parse('cancelled'), RequestStatus.cancelled);
      expect(RequestStatus.parse('new_thing'), RequestStatus.other);
    });

    test('a row without an id is skipped, and a bare row still parses', () {
      expect(VenueRequest.tryParse({'status': 'pending'}), isNull);
      final bare = VenueRequest.tryParse({'id': 'x'})!;
      expect(bare.venueName, '');
      expect(bare.price, isNull);
      expect(bare.needsReply, isFalse);
    });
  });

  group('SpaceListing', () {
    test('groups its status for filtering', () {
      SpaceListing with_(String status) =>
          SpaceListing(id: '1', name: 'x', status: status);

      expect(with_('available').group, 'live');
      expect(with_('published').group, 'live');
      expect(with_('pending').group, 'pending');
      expect(with_('rejected').group, 'rejected');
      expect(with_('archived').group, 'archived');
      expect(with_('draft').group, 'draft');
      expect(with_('').group, 'draft');
    });

    test('is found by name or town, ignoring case', () {
      const l = SpaceListing(
        id: '1',
        name: 'Sky Hall',
        status: 'available',
        city: 'Baguio',
      );

      expect(l.matches(''), isTrue);
      expect(l.matches('  '), isTrue);
      expect(l.matches('sky'), isTrue);
      expect(l.matches('BAGUIO'), isTrue);
      expect(l.matches('hall b'), isFalse);
      expect(l.matches('manila'), isFalse);
    });

    test('reads a venue, with its city', () {
      final l = SpaceListing.tryParse({
        'id': 'v1',
        'name': 'Sky Hall',
        'status': 'available',
        'city': 'Baguio',
        'images': [
          {'url': 'https://x.test/v.png'},
        ],
      })!;

      expect(l.name, 'Sky Hall');
      expect(l.city, 'Baguio');
      expect(l.status, 'available');
      expect(l.imageUrl, 'https://x.test/v.png');
    });

    test('reads an event template, whose place is targetCity', () {
      final l = SpaceListing.tryParse(
        {
          'id': 'e1',
          'name': 'Bonfire',
          'status': 'published',
          'targetCity': 'Baguio',
        },
        cityKey: 'targetCity',
      )!;

      expect(l.city, 'Baguio');
    });

    test('images may be plain strings', () {
      final l = SpaceListing.tryParse({
        'id': 'v1',
        'name': 'A',
        'images': ['https://x.test/s.png'],
      })!;

      expect(l.imageUrl, 'https://x.test/s.png');
    });
  });

  group('CheckInResult', () {
    test('reads the message and whether a payout went out', () {
      final r = CheckInResult.fromJson(const {
        'data': {'message': 'Checked in', 'payoutTriggered': true},
      });

      expect(r.message, 'Checked in');
      expect(r.payoutTriggered, isTrue);
    });

    test('copes with an empty answer', () {
      expect(CheckInResult.fromJson(null).message, isNull);
      expect(
        CheckInResult.fromJson(const {'data': <String, Object>{}})
            .payoutTriggered,
        isFalse,
      );
    });
  });

  group('SpacesRepository', () {
    late _MockApi api;
    late SpacesRepository repo;

    setUp(() {
      api = _MockApi();
      repo = SpacesRepository(api, 'u1');
    });

    test('lists requests with the ones awaiting a reply first', () async {
      when(() => api.get(ApiEndpoints.providerRequests)).thenAnswer(
        (_) async => {
          'venues': [
            _row('old', status: 'approved'),
            _row('new'),
            _row('pending', status: 'pending'),
            _row('new2'),
          ],
          'assets': <Object>[],
        },
      );

      final list = await repo.venueRequests();

      expect([for (final r in list) r.id], ['new', 'new2', 'old', 'pending']);
    });

    test('a response with no venues list is an error, not an empty list', () {
      when(() => api.get(ApiEndpoints.providerRequests))
          .thenAnswer((_) async => {'assets': <Object>[]});

      expect(repo.venueRequests(), throwsFormatException);
    });

    test('accepting sends confirm for a venue', () async {
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});

      await repo.reviewVenueRequest('r1', accept: true);

      verify(
        () => api.patch(
          ApiEndpoints.requestReview('r1'),
          {'type': 'venue', 'action': 'confirm'},
        ),
      ).called(1);
    });

    test('declining sends reject', () async {
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});

      await repo.reviewVenueRequest('r1', accept: false);

      verify(
        () => api.patch(
          ApiEndpoints.requestReview('r1'),
          {'type': 'venue', 'action': 'reject'},
        ),
      ).called(1);
    });

    test('my venues are asked for by host', () async {
      when(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'data': [
            {'id': 'v1', 'name': 'Sky Hall', 'status': 'available'},
          ],
        },
      );

      final list = await repo.myVenues();

      expect(list.single.name, 'Sky Hall');
      verify(
        () => api.get(
          ApiEndpoints.venues,
          query: {'hostId': 'u1', 'limit': 100, 'page': 1},
        ),
      ).called(1);
    });

    test('my venues come page by page until all are in', () async {
      Map<String, Object> page(int from, int count) => {
            'venues': [
              for (var i = from; i < from + count; i++)
                {'id': 'v$i', 'name': 'Venue $i', 'status': 'available'},
            ],
            'total': 130,
          };
      when(
        () => api.get(
          ApiEndpoints.venues,
          query: {'hostId': 'u1', 'limit': 100, 'page': 1},
        ),
      ).thenAnswer((_) async => page(0, 100));
      when(
        () => api.get(
          ApiEndpoints.venues,
          query: {'hostId': 'u1', 'limit': 100, 'page': 2},
        ),
      ).thenAnswer((_) async => page(100, 30));

      final list = await repo.myVenues();

      expect(list, hasLength(130));
      expect(list.last.id, 'v129');
      verifyNever(
        () => api.get(
          ApiEndpoints.venues,
          query: {'hostId': 'u1', 'limit': 100, 'page': 3},
        ),
      );
    });

    test('stops asking once the total is reached on a full page', () async {
      when(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'venues': [
            for (var i = 0; i < 100; i++)
              {'id': 'v$i', 'name': 'Venue $i', 'status': 'available'},
          ],
          'total': 100,
        },
      );

      expect(await repo.myVenues(), hasLength(100));
      verify(() => api.get(ApiEndpoints.venues, query: any(named: 'query')))
          .called(1);
    });

    test('my events are asked for by owner, from either list key', () async {
      when(() => api.get(ApiEndpoints.events, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'templates': [
            {'id': 'e1', 'name': 'Bonfire', 'status': 'published'},
          ],
        },
      );

      final list = await repo.myEvents();

      expect(list.single.name, 'Bonfire');
      verify(
        () => api.get(
          ApiEndpoints.events,
          query: {'ownerId': 'u1', 'limit': 50},
        ),
      ).called(1);
    });

    test('with nobody signed in there is nothing to list', () async {
      final signedOut = SpacesRepository(api, null);

      expect(await signedOut.myVenues(), isEmpty);
      verifyNever(() => api.get(any(), query: any(named: 'query')));
    });

    test('check-in sends the trimmed ticket code', () async {
      when(() => api.patch(any(), any())).thenAnswer(
        (_) async => {
          'data': {'message': 'Checked in'},
        },
      );

      final result = await repo.checkIn('  FX-123  ');

      expect(result.message, 'Checked in');
      verify(
        () => api.patch(
          ApiEndpoints.bookingCheckIn,
          {'ticketCode': 'FX-123'},
        ),
      ).called(1);
    });
  });
}
