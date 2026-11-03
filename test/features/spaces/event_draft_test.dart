import 'package:flutter_template/features/spaces/domain/event_detail.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_test/flutter_test.dart';

PackageItem _venue({
  double cost = 50000,
  VenueAccess access = VenueAccess.approved,
}) =>
    PackageItem(
      id: 'v1',
      name: 'Sky Hall',
      kind: PackageKind.venue,
      cost: cost,
      icon: 'location_city',
      access: access,
    );

const _dj = PackageItem(
  id: 's1',
  name: 'DJ Kai',
  kind: PackageKind.talent,
  cost: 8000,
  icon: 'music_note',
  savedAsService: true,
);

const _sound = PackageItem(
  id: 'a1',
  name: 'Sound system',
  kind: PackageKind.asset,
  cost: 5000,
  icon: 'speaker',
);

String _words(int n) => List.filled(n, 'word').join(' ');

void main() {
  group('categories', () {
    test('map to the API values, and anything unknown is other', () {
      expect(eventCategoryValue('Corporate'), 'corporate');
      expect(eventCategoryValue('Birthday'), 'birthday');
      expect(eventCategoryValue('Wedding'), 'wedding');
      expect(eventCategoryValue('Social'), 'social');
      expect(eventCategoryValue('Other'), 'other');
      expect(eventCategoryValue(null), 'other');
      expect(eventCategoryValue('Popup'), 'other');
    });

    test('read back from the API values', () {
      expect(eventCategoryLabel('corporate'), 'Corporate');
      expect(eventCategoryLabel('SOCIAL'), 'Social');
      expect(eventCategoryLabel('fair'), 'Other');
      expect(eventCategoryLabel(null), 'Other');
    });

    test('Other keeps its own label at the top of the description', () {
      expect(
        withCategoryOtherNote('A fun day', 'Other', ' Pop-up market '),
        'Event type: Pop-up market\n\nA fun day',
      );
      // Only Other has a label to keep, and only once it is filled in.
      expect(withCategoryOtherNote('A fun day', 'Social', 'x'), 'A fun day');
      expect(withCategoryOtherNote('A fun day', 'Other', '  '), 'A fun day');
    });

    test('and the label is read back out of the description', () {
      final split =
          splitCategoryOtherNote('Event type: Pop-up market\n\nA fun');

      expect(split.categoryOther, 'Pop-up market');
      expect(split.description, 'A fun');
      expect(splitCategoryOtherNote('Plain').categoryOther, isEmpty);
      expect(splitCategoryOtherNote('Plain').description, 'Plain');
    });
  });

  group('words', () {
    test('are counted as the web counts them', () {
      expect(countWords(''), 0);
      expect(countWords('   '), 0);
      expect(countWords('one'), 1);
      expect(countWords('  one   two\nthree '), 3);
    });
  });

  group('readiness', () {
    test('needs a title, a category and an approved venue', () {
      var draft = const EventDraft();
      expect(draft.readyToSubmit, isFalse);

      draft = draft.copyWith(title: 'Bonfire', category: 'Social');
      expect(draft.readyToSubmit, isFalse);

      draft = draft.copyWith(items: [_venue()]);
      expect(draft.readyToSubmit, isTrue);
    });

    test('a venue still pending or not applied for does not count', () {
      const base = EventDraft(title: 'Bonfire', category: 'Social');

      final pending = base.copyWith(
        items: [_venue(access: VenueAccess.pending)],
      );
      final none = base.copyWith(items: [_venue(access: VenueAccess.none)]);

      expect(pending.readyToSubmit, isFalse);
      expect(none.readyToSubmit, isFalse);
    });

    test('Other also needs its own label', () {
      final draft = EventDraft(
        title: 'Bonfire',
        category: 'Other',
        items: [_venue()],
      );

      expect(draft.readyToSubmit, isFalse);
      expect(draft.categoryOtherMissing, isTrue);
      expect(draft.copyWith(categoryOther: 'Market').readyToSubmit, isTrue);
    });

    test('five photos and 100 words are only recommended', () {
      final draft = EventDraft(
        title: 'Bonfire',
        category: 'Social',
        items: [_venue()],
      );
      final lines = {for (final l in draft.readiness) l.id: l};

      expect(draft.readyToSubmit, isTrue);
      expect(lines['gallery']!.required, isFalse);
      expect(lines['description']!.required, isFalse);
      expect(lines['gallery']!.met, isFalse);
      expect(lines['description']!.met, isFalse);
    });

    test('the score is the share of lines met', () {
      var draft = const EventDraft();
      expect(draft.score, 0);

      draft = EventDraft(
        title: 'Bonfire',
        category: 'Social',
        items: [_venue()],
        description: _words(100),
        photos: [
          for (var i = 0; i < 5; i++)
            VenuePhoto(fileId: 'f$i', url: 'https://x.test/$i'),
        ],
      );
      expect(draft.score, 100);

      expect(draft.copyWith(photos: const []).score, 80);
    });
  });

  group('the package', () {
    test('totals split into venue, talent and the rest', () {
      final draft = EventDraft(items: [_venue(), _dj, _sound]);
      final t = draft.totals;

      expect(t.base, 63000);
      expect(t.venue, 50000);
      expect(t.talent, 8000);
      expect(t.services, 5000);
      // 20% on top, as the web's default.
      expect(t.suggested, closeTo(75600, 0.001));
    });

    test('an agreed price counts instead of the listed one', () {
      final draft = EventDraft(
        items: [_venue().copyWith(agreedPrice: 40000), _sound],
      );

      expect(draft.totals.venue, 40000);
      expect(draft.totals.base, 45000);
    });

    test('items are grouped by their icon, as on the web', () {
      // A photographer listed as an asset is talent by its camera icon.
      const photographer = PackageItem(
        id: 'a2',
        name: 'Photo',
        kind: PackageKind.asset,
        cost: 3000,
        icon: 'camera_alt',
      );

      expect(const EventDraft(items: [photographer]).totals.talent, 3000);
      expect(const EventDraft(items: [photographer]).totals.services, 0);
    });

    test('only one venue is the venue of the event', () {
      expect(EventDraft(items: [_dj, _venue()]).venue!.id, 'v1');
      expect(const EventDraft(items: [_dj]).venue, isNull);
    });
  });

  group('the saved body', () {
    test('matches what the web sends', () {
      final json = const EventDraft(
        title: ' Bonfire Night ',
        category: 'Social',
        description: 'A fun night',
        maxAttendees: 80,
        country: 'Philippines',
        state: 'Benguet',
        city: 'Baguio',
        lat: 16.4,
        lng: 120.6,
        cancellationPolicyId: 'p1',
        photos: [VenuePhoto(fileId: 'f1', url: 'u')],
      ).toJson();

      expect(json, {
        'name': 'Bonfire Night',
        'description': 'A fun night',
        'category': 'social',
        'isPublic': false,
        'maxAttendees': 80,
        'cancellationPolicyId': 'p1',
        'targetCity': 'Baguio',
        'targetState': 'Benguet',
        'targetCountry': 'Philippines',
        'lat': 16.4,
        'lng': 120.6,
        'imgIds': ['f1'],
      });
    });

    test('leaves out what is empty, and is never public', () {
      final json = const EventDraft(title: 'Bonfire').toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('targetCity'), isFalse);
      expect(json.containsKey('lat'), isFalse);
      expect(json.containsKey('imgIds'), isFalse);
      expect(json.containsKey('cancellationPolicyId'), isFalse);
      expect(json['isPublic'], isFalse);
      expect(json['category'], 'other');
      expect(json['maxAttendees'], 100);
    });

    test('keeps the Other label in the description', () {
      final json = const EventDraft(
        title: 'Market',
        category: 'Other',
        categoryOther: 'Pop-up',
        description: 'Come',
      ).toJson();

      expect(json['category'], 'other');
      expect(json['description'], 'Event type: Pop-up\n\nCome');
    });

    test('a new event with no description gets the web default', () {
      const draft = EventDraft(title: 'Bonfire');

      // The API cannot create an event without a description.
      expect(
        draft.toJson(forCreate: true)['description'],
        'Event created via Creator Studio.',
      );
      // An update leaves it out, so what is saved stays.
      expect(draft.toJson().containsKey('description'), isFalse);
    });

    test('the default is not used when there is a description', () {
      const draft = EventDraft(title: 'Bonfire', description: 'A fun night');

      expect(draft.toJson(forCreate: true)['description'], 'A fun night');
    });

    test('the default is hidden when the event is read back', () {
      final detail = EventDetail.tryParse({
        'template': {
          'id': 't1',
          'name': 'Bonfire',
          'category': 'social',
          'description': 'Event created via Creator Studio.',
        },
      })!;

      expect(detail.draft.description, isEmpty);
      expect(detail.draft.words, 0);
    });

    test('no attendees means none is sent', () {
      expect(
        const EventDraft(title: 'x', maxAttendees: 0)
            .toJson()
            .containsKey('maxAttendees'),
        isFalse,
      );
    });
  });

  group('reading an event back', () {
    Map<String, dynamic> template({String category = 'social'}) => {
          'id': 't1',
          'name': 'Bonfire Night',
          'status': 'draft',
          'category': category,
          'description': 'A fun night',
          'maxAttendees': 80,
          'targetCity': 'Baguio',
          'targetState': 'Benguet',
          'targetCountry': 'Philippines',
          'lat': '16.4',
          'lng': 120.6,
          'cancellationPolicyId': 'p1',
          'images': [
            {'id': 'f1', 'url': 'https://x.test/1.png'},
          ],
          'templateVenues': [
            {
              'venueId': 'v1',
              'agreedPrice': '45000',
              'isOptional': false,
              'venue': {'id': 'v1', 'name': 'Sky Hall', 'price': '50000'},
            },
          ],
          'templateAssets': [
            {
              'assetId': 'a1',
              'agreedPrice': '4000',
              'isOptional': true,
              'asset': {
                'id': 'a1',
                'name': 'Sound',
                'price': '5000',
                'category': 'sound_system',
              },
            },
          ],
          'templateServices': [
            {
              'serviceId': 's1',
              'agreedPrice': null,
              'isOptional': false,
              'service': {
                'id': 's1',
                'name': 'DJ Kai',
                'price': '8000',
                'category': 'dj',
              },
            },
          ],
        };

    test('fills the draft from the saved event', () {
      final detail = EventDetail.tryParse({'template': template()})!;
      final d = detail.draft;

      expect(detail.isDraft, isTrue);
      expect(d.title, 'Bonfire Night');
      expect(d.category, 'Social');
      expect(d.description, 'A fun night');
      expect(d.maxAttendees, 80);
      expect(d.city, 'Baguio');
      expect(d.lat, 16.4);
      expect(d.cancellationPolicyId, 'p1');
      expect(d.photos.single.fileId, 'f1');
      expect(d.items.map((i) => i.id), ['v1', 'a1', 's1']);
    });

    test('keeps the agreed price and optional flag of each item', () {
      final d = EventDetail.tryParse({'template': template()})!.draft;

      expect(d.items[0].agreedPrice, 45000);
      expect(d.items[0].price, 45000);
      expect(d.items[1].agreedPrice, 4000);
      expect(d.items[1].isOptional, isTrue);
      expect(d.items[2].agreedPrice, isNull);
      expect(d.items[2].price, 8000);
    });

    test('a venue already on the event is one the host may keep', () {
      final d = EventDetail.tryParse({'template': template()})!.draft;

      expect(d.venue!.access, VenueAccess.approved);
      expect(d.hasApprovedVenue, isTrue);
    });

    test('reads the Other label back out of the description', () {
      final t = template(category: 'other')
        ..['description'] = 'Event type: Pop-up\n\nCome along';
      final d = EventDetail.tryParse({'template': t})!.draft;

      expect(d.category, 'Other');
      expect(d.categoryOther, 'Pop-up');
      expect(d.description, 'Come along');
    });

    test('a submitted or live event cannot be sent again', () {
      for (final status in ['pending', 'published', 'rejected', 'archived']) {
        final t = template()..['status'] = status;
        expect(EventDetail.tryParse({'template': t})!.isDraft, isFalse);
      }
    });

    test('a saved event gives back the body it was saved with', () {
      final d = EventDetail.tryParse({'template': template()})!.draft;
      final json = d.toJson();

      expect(json['name'], 'Bonfire Night');
      expect(json['category'], 'social');
      expect(json['maxAttendees'], 80);
      expect(json['targetCountry'], 'Philippines');
    });

    test('rows it cannot read are refused', () {
      expect(EventDetail.tryParse(null), isNull);
      expect(
        EventDetail.tryParse({
          'template': {'name': 'x'},
        }),
        isNull,
      );
    });
  });

  group('picker items', () {
    test('a venue carries its place, to fill in the event', () {
      final v = packageItemFromVenue(
        {
          'id': 'v1',
          'name': 'Sky Hall',
          'price': '50000',
          'city': 'Baguio',
          'state': 'Benguet',
          'country': 'Philippines',
          'lat': 16.4,
          'lng': 120.6,
          'images': [
            {'url': 'https://x.test/a.png'},
          ],
        },
        access: VenueAccess.none,
      )!;

      expect(v.cost, 50000);
      expect(v.city, 'Baguio');
      expect(v.lat, 16.4);
      expect(v.imageUrl, 'https://x.test/a.png');
      expect(v.access, VenueAccess.none);
      expect(bucketOf(v), ResourceBucket.venue);
    });

    test('assets are sorted as the web sorts them', () {
      PackageItem asset(String category) => packageItemFromAsset(
            {'id': 'x', 'name': 'n', 'price': '1', 'category': category},
          )!;

      expect(bucketOf(asset('entertainment')), ResourceBucket.talent);
      expect(asset('entertainment').icon, 'music_note');
      expect(bucketOf(asset('sound_system')), ResourceBucket.equipment);
      expect(bucketOf(asset('equipment')), ResourceBucket.equipment);
      expect(bucketOf(asset('catering')), ResourceBucket.service);
      expect(asset('catering').icon, 'restaurant');
      expect(asset('photography').icon, 'camera_alt');
      expect(asset('planning').icon, 'event_note');
      expect(asset('furniture').icon, 'brush');
      expect(bucketOf(asset('anything else')), ResourceBucket.service);
    });

    test('a talent asset is saved as an asset', () {
      final a = packageItemFromAsset(
        {'id': 'x', 'name': 'Band', 'category': 'entertainment'},
      )!;

      expect(a.isService, isFalse);
    });

    test('performing services are talent, the others are services', () {
      PackageItem service(String category) => packageItemFromService(
            {'id': 'x', 'name': 'n', 'price': '1', 'category': category},
          )!;

      expect(bucketOf(service('dj')), ResourceBucket.talent);
      expect(service('dj').icon, 'music_note');
      expect(service('mc').icon, 'mic');
      expect(service('videography').icon, 'videocam');
      expect(bucketOf(service('catering')), ResourceBucket.service);
      expect(service('catering').icon, 'restaurant');
      expect(service('other').icon, 'work_outline');
    });

    test('a service is always saved as a service, even as talent', () {
      final dj = packageItemFromService(
        {'id': 'x', 'name': 'DJ', 'category': 'dj'},
      )!;

      expect(dj.kind, PackageKind.talent);
      expect(dj.isService, isTrue);
    });

    test('a category may be a name or an object', () {
      final a = packageItemFromAsset(
        {
          'id': 'x',
          'name': 'n',
          'category': {'slug': 'Entertainment'},
        },
      )!;

      expect(bucketOf(a), ResourceBucket.talent);
    });

    test('a price of nothing is nothing, not a made-up default', () {
      final v = packageItemFromVenue(
        {'id': 'v', 'name': 'Free Hall', 'price': 0},
        access: VenueAccess.approved,
      )!;

      expect(v.cost, 0);
    });

    test('rows without an id are skipped', () {
      expect(packageItemFromAsset({'name': 'x'}), isNull);
      expect(packageItemFromService(null), isNull);
      expect(packageItemFromVenue('x', access: VenueAccess.none), isNull);
    });
  });
}
