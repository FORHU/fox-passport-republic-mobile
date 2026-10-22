import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const _venue = PackageItem(
  id: 'v1',
  name: 'Sky Hall',
  kind: PackageKind.venue,
  cost: 50000,
  icon: 'location_city',
);

const _sound = PackageItem(
  id: 'a1',
  name: 'Sound',
  kind: PackageKind.asset,
  cost: 5000,
  icon: 'speaker',
);

const _dj = PackageItem(
  id: 's1',
  name: 'DJ Kai',
  kind: PackageKind.talent,
  cost: 8000,
  icon: 'music_note',
  savedAsService: true,
);

void main() {
  late _MockApi api;
  late SpacesRepository repo;

  setUp(() {
    api = _MockApi();
    repo = SpacesRepository(api, 'u1');
    when(() => api.post(any(), any())).thenAnswer((_) async => {});
    when(() => api.post(any())).thenAnswer((_) async => {});
    when(() => api.put(any(), any())).thenAnswer((_) async => {});
    when(() => api.delete(any())).thenAnswer((_) async => {});
  });

  /// What the API says the event already holds.
  void holds({
    List<String> venues = const [],
    List<String> assets = const [],
    List<String> services = const [],
  }) {
    when(() => api.get('/event-templates/t1')).thenAnswer(
      (_) async => {
        'template': {
          'id': 't1',
          'templateVenues': [
            for (final id in venues) {'venueId': id},
          ],
          'templateAssets': [
            for (final id in assets) {'assetId': id},
          ],
          'templateServices': [
            for (final id in services) {'serviceId': id},
          ],
        },
      },
    );
  }

  group('saving the event', () {
    const draft = EventDraft(title: 'Bonfire', category: 'Social');

    test('creates it as a draft and gives back its id', () async {
      when(() => api.post('/event-templates', any())).thenAnswer(
        (_) async => {
          'template': {'id': 't9'},
        },
      );

      expect(await repo.createEvent(draft), 't9');
      final body = verify(() => api.post('/event-templates', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body['name'], 'Bonfire');
      expect(body['category'], 'social');
      expect(body['isPublic'], isFalse);
      // A status is never sent: the API decides, and a new event is a draft.
      expect(body.containsKey('status'), isFalse);
    });

    test('fails when the API gives no id back', () async {
      when(() => api.post('/event-templates', any()))
          .thenAnswer((_) async => {});

      expect(() => repo.createEvent(draft), throwsA(isA<FormatException>()));
    });

    test('updates it by id without touching its status', () async {
      await repo.updateEvent('t1', draft);

      final body = verify(() => api.put('/event-templates/t1', captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body['name'], 'Bonfire');
      expect(body.containsKey('status'), isFalse);
    });

    test('sends it for review through the submit route', () async {
      await repo.submitEvent('t1');

      verify(() => api.post('/event-templates/t1/submit')).called(1);
    });

    test('reads an event back to edit', () async {
      when(() => api.get('/event-templates/t1')).thenAnswer(
        (_) async => {
          'template': {
            'id': 't1',
            'name': 'Bonfire',
            'status': 'pending',
            'category': 'social',
          },
        },
      );

      final detail = await repo.eventDetail('t1');

      expect(detail.draft.title, 'Bonfire');
      expect(detail.isDraft, isFalse);
    });
  });

  group('syncing the package', () {
    test('attaches a new venue, asset and service as the web does', () async {
      holds();

      final problems = await repo.syncEventPackage('t1', [
        _venue.copyWith(agreedPrice: 45000),
        _sound.copyWith(isOptional: true),
        _dj,
      ]);

      expect(problems, isEmpty);
      verify(
        () => api.post('/event-templates/t1/venues', {
          'venueId': 'v1',
          'agreedPrice': 45000.0,
          'isOptional': false,
        }),
      ).called(1);
      verify(
        () => api.post('/event-templates/t1/assets', {
          'assetId': 'a1',
          'quantity': 1,
          'agreedPrice': 5000.0,
          'isOptional': true,
        }),
      ).called(1);
      // Talent that is a service goes in as a service.
      verify(
        () => api.post('/event-templates/t1/services', {
          'serviceId': 's1',
          'agreedPrice': 8000.0,
          'isOptional': false,
        }),
      ).called(1);
    });

    test('sends the listed price when none was agreed', () async {
      holds();

      await repo.syncEventPackage('t1', [_sound]);

      verify(
        () => api.post('/event-templates/t1/assets', {
          'assetId': 'a1',
          'quantity': 1,
          'agreedPrice': 5000.0,
          'isOptional': false,
        }),
      ).called(1);
    });

    test('removes what the host took out', () async {
      holds(venues: ['v1'], assets: ['a1'], services: ['s1']);

      await repo.syncEventPackage('t1', const []);

      verify(() => api.delete('/event-templates/t1/venues/v1')).called(1);
      verify(() => api.delete('/event-templates/t1/assets/a1')).called(1);
      verify(() => api.delete('/event-templates/t1/services/s1')).called(1);
      verifyNever(() => api.post(any(), any()));
    });

    test('leaves alone what is already there and unchanged', () async {
      holds(venues: ['v1'], assets: ['a1'], services: ['s1']);

      await repo.syncEventPackage(
        't1',
        [_venue, _sound, _dj],
        before: [_venue, _sound, _dj],
      );

      verifyNever(() => api.post(any(), any()));
      verifyNever(() => api.delete(any()));
    });

    test('a different venue replaces the old one', () async {
      holds(venues: ['v1']);
      const other = PackageItem(
        id: 'v2',
        name: 'Old Barn',
        kind: PackageKind.venue,
        cost: 20000,
        icon: 'location_city',
      );

      await repo.syncEventPackage('t1', [other], before: [_venue]);

      verifyInOrder([
        () => api.delete('/event-templates/t1/venues/v1'),
        () => api.post('/event-templates/t1/venues', any()),
      ]);
    });

    test('a changed price is sent again, and an unchanged one is not',
        () async {
      holds(assets: ['a1'], services: ['s1']);

      await repo.syncEventPackage(
        't1',
        [_sound.copyWith(agreedPrice: 4000), _dj],
        before: [_sound, _dj],
      );

      verifyInOrder([
        () => api.delete('/event-templates/t1/assets/a1'),
        () => api.post(
              '/event-templates/t1/assets',
              {
                'assetId': 'a1',
                'quantity': 1,
                'agreedPrice': 4000.0,
                'isOptional': false,
              },
            ),
      ]);
      verifyNever(() => api.delete('/event-templates/t1/services/s1'));
    });

    test('says which item the API refused, and why', () async {
      holds();
      when(() => api.post('/event-templates/t1/venues', any())).thenThrow(
        const UnauthorizedException(
          'Unauthorized: you need an approved affiliation with this venue',
        ),
      );

      final problems = await repo.syncEventPackage('t1', [_venue, _sound]);

      expect(problems, hasLength(1));
      expect(problems.single.name, 'Sky Hall');
      expect(problems.single.message, contains('approved affiliation'));
      // One refusal does not stop the rest.
      verify(() => api.post('/event-templates/t1/assets', any())).called(1);
    });

    test('a refusal with no words is still reported', () async {
      holds();
      when(() => api.post('/event-templates/t1/assets', any()))
          .thenThrow(Exception('boom'));

      final problems = await repo.syncEventPackage('t1', [_sound]);

      expect(problems.single.name, 'Sound');
      expect(problems.single.message, isEmpty);
    });
  });

  group('the lists to choose from', () {
    test('only live venues are offered, and searches are sent', () async {
      when(() => api.get('/venues', query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'venues': [
            {'id': 'v1', 'name': 'Live Hall', 'status': 'available'},
            {'id': 'v2', 'name': 'Draft Hall', 'status': 'draft'},
            {'id': 'v3', 'name': 'Review Hall', 'status': 'pending'},
          ],
          'total': 3,
        },
      );

      final result = await repo.venueChoices(query: ' hall ', page: 2);

      expect(result.items.map((i) => i.name), ['Live Hall']);
      expect(result.total, 3);
      verify(
        () => api.get(
          '/venues',
          query: {'limit': 50, 'page': 2, 'search': 'hall'},
        ),
      ).called(1);
    });

    test('no search sends none', () async {
      when(() => api.get('/venues', query: any(named: 'query')))
          .thenAnswer((_) async => {'venues': <Object>[]});

      await repo.venueChoices();

      verify(() => api.get('/venues', query: {'limit': 50, 'page': 1}))
          .called(1);
    });

    test('assets and services are read by their own keys', () async {
      when(() => api.get('/asset', query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'assets': [
            {
              'id': 'a1',
              'name': 'Sound',
              'price': '5000',
              'category': 'sound_system',
            },
          ],
          'total': 120,
        },
      );
      when(() => api.get('/service', query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'services': [
            {'id': 's1', 'name': 'DJ', 'price': '8000', 'category': 'dj'},
            {'name': 'no id'},
          ],
        },
      );

      final assets = await repo.assetChoices();
      final services = await repo.serviceChoices(page: 3);

      expect(assets.items.single.icon, 'speaker');
      expect(assets.total, 120);
      expect(services.items.single.name, 'DJ');
      expect(services.items.single.isService, isTrue);
      expect(services.total, 1);
      verify(() => api.get('/service', query: {'limit': 50, 'page': 3}))
          .called(1);
    });
  });
}
