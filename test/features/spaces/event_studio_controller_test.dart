import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/event_detail.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/event_studio_controller.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpacesRepository {}

class _FakeLocator implements DeviceLocator {
  LocateResult result =
      const LocateResult(LocateOutcome.ok, lat: 14.6, lng: 121);
  DevicePlace place = const DevicePlace(city: 'Quezon City', countryCode: 'PH');

  @override
  Future<LocateResult> locate({bool prompt = true}) async => result;

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async => place;
}

const _venue = PackageItem(
  id: 'v1',
  name: 'Sky Hall',
  kind: PackageKind.venue,
  cost: 50000,
  icon: 'location_city',
  city: 'Baguio',
  state: 'Benguet',
  country: 'Philippines',
  lat: 16.4,
  lng: 120.6,
);

const _barn = PackageItem(
  id: 'v2',
  name: 'Old Barn',
  kind: PackageKind.venue,
  cost: 20000,
  icon: 'location_city',
);

const _sound = PackageItem(
  id: 'a1',
  name: 'Sound',
  kind: PackageKind.asset,
  cost: 5000,
  icon: 'speaker',
);

Partner _partner(String venueId, String status) => Partner.tryParse(
      {
        'id': 'p-$venueId-$status',
        'status': status,
        'initiatedBy': 'eventFoxer',
        'venue': {'id': venueId, 'name': venueId},
        'eventFoxer': {'id': 'e1', 'name': 'Ada'},
      },
      PartnerSide.eventFoxer,
    )!;

void main() {
  late _MockRepo repo;
  late _FakeLocator locator;
  var owned = <SpaceListing>[];
  var partners = const PartnerLists();

  setUpAll(() {
    registerFallbackValue(const EventDraft());
    registerFallbackValue(PickedPhoto(bytes: Uint8List(0), name: ''));
    registerFallbackValue(<PackageItem>[]);
  });

  setUp(() {
    repo = _MockRepo();
    locator = _FakeLocator();
    owned = [
      const SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available'),
    ];
    partners = const PartnerLists();
    when(() => repo.cancellationPolicies()).thenAnswer((_) async => const []);
    when(() => repo.countries()).thenAnswer(
      (_) async => const [
        PlaceOption(code: 'PH', name: 'Philippines'),
        PlaceOption(code: 'US', name: 'United States'),
      ],
    );
    when(() => repo.states(any())).thenAnswer((_) async => const []);
    when(() => repo.cities(any(), stateCode: any(named: 'stateCode')))
        .thenAnswer((_) async => ['Baguio', 'Quezon City']);
    when(() => repo.createEvent(any())).thenAnswer((_) async => 't1');
    when(() => repo.updateEvent(any(), any())).thenAnswer((_) async {});
    when(() => repo.submitEvent(any())).thenAnswer((_) async {});
    when(
      () => repo.syncEventPackage(
        any(),
        any(),
        before: any(named: 'before'),
      ),
    ).thenAnswer((_) async => const <PackageProblem>[]);
  });

  ProviderContainer open([String? id]) {
    final c = ProviderContainer(
      overrides: [
        spacesRepositoryProvider.overrideWithValue(repo),
        deviceLocatorProvider.overrideWithValue(locator),
        myVenuesProvider.overrideWith((ref) async => owned),
        partnersProvider.overrideWith((ref) async => partners),
      ],
    );
    addTearDown(c.dispose);
    // Kept alive, as the screen would, so the controller survives the test.
    c.listen(eventStudioProvider(id), (_, __) {});
    return c;
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  EventStudioState read(ProviderContainer c, [String? id]) =>
      c.read(eventStudioProvider(id));

  EventStudioController studio(ProviderContainer c, [String? id]) =>
      c.read(eventStudioProvider(id).notifier);

  /// A draft that can be submitted.
  EventDraft ready() => const EventDraft(
        title: 'Bonfire',
        category: 'Social',
        items: [_venue],
      );

  group('starting', () {
    test('a new event starts empty, on the first step, and not ready',
        () async {
      final c = open();
      await settle();

      final s = read(c);
      expect(s.isNew, isTrue);
      expect(s.loading, isFalse);
      expect(s.step, EventStep.basics);
      expect(s.canSubmit, isFalse);
      expect(s.draft.maxAttendees, 100);
    });

    test('steps forward and back, and not past either end', () async {
      final c = open();
      final s = studio(c)
        ..back()
        ..next()
        ..next();
      expect(read(c).step, EventStep.photos);

      for (var i = 0; i < 10; i++) {
        s.next();
      }
      expect(read(c).step, EventStep.review);
    });

    test('loads a saved event to edit, remembering its status', () async {
      when(() => repo.eventDetail('t1')).thenAnswer(
        (_) async => EventDetail(
          id: 't1',
          status: 'pending',
          draft: ready(),
        ),
      );
      final c = open('t1');
      expect(read(c, 't1').loading, isTrue);
      await settle();

      final s = read(c, 't1');
      expect(s.loading, isFalse);
      expect(s.eventId, 't1');
      expect(s.status, 'pending');
      expect(s.draft.title, 'Bonfire');
      expect(s.baseline.single.id, 'v1');
    });

    test('says so when the event cannot be loaded', () async {
      when(() => repo.eventDetail('t1')).thenThrow(Exception('down'));
      final c = open('t1');
      await settle();

      expect(read(c, 't1').loadFailed, isTrue);
    });
  });

  group('which venues the host may use', () {
    test('their own are approved, others follow their affiliation', () async {
      partners = PartnerLists(
        asEventFoxer: [
          _partner('v2', 'approved'),
          _partner('v3', 'pending'),
        ],
      );
      final c = open();
      await settle();
      final s = read(c);

      expect(s.accessFor('v1'), VenueAccess.approved);
      expect(s.accessFor('v2'), VenueAccess.approved);
      expect(s.accessFor('v3'), VenueAccess.pending);
      expect(s.accessFor('v4'), VenueAccess.none);
    });

    test('a rejected affiliation gives no access', () async {
      partners = PartnerLists(asEventFoxer: [_partner('v2', 'rejected')]);
      final c = open();
      await settle();

      expect(read(c).accessFor('v2'), VenueAccess.none);
    });

    test('an approved affiliation wins over a pending one', () async {
      partners = PartnerLists(
        asEventFoxer: [_partner('v2', 'pending'), _partner('v2', 'approved')],
      );
      final c = open();
      await settle();

      expect(read(c).accessFor('v2'), VenueAccess.approved);
    });
  });

  group('the package', () {
    test('an approved venue is added', () async {
      final c = open();
      await settle();

      expect(studio(c).addItem(_venue), AddResult.added);
      expect(read(c).draft.venue!.id, 'v1');
    });

    test('a venue with no affiliation is refused, and one pending too',
        () async {
      partners = PartnerLists(asEventFoxer: [_partner('v3', 'pending')]);
      final c = open();
      await settle();
      final s = studio(c);
      const pending = PackageItem(
        id: 'v3',
        name: 'Pending Hall',
        kind: PackageKind.venue,
        cost: 1,
        icon: 'location_city',
      );

      expect(s.addItem(_barn), AddResult.venueNotApplied);
      expect(s.addItem(pending), AddResult.venuePending);
      expect(read(c).draft.items, isEmpty);
    });

    test('only one venue is allowed', () async {
      owned = const [
        SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available'),
        SpaceListing(id: 'v2', name: 'Old Barn', status: 'available'),
      ];
      final c = open();
      await settle();
      final s = studio(c);

      expect(s.addItem(_venue), AddResult.added);
      expect(s.addItem(_barn), AddResult.alreadyHasVenue);
      expect(read(c).draft.items, hasLength(1));
    });

    test('the same item is not added twice', () async {
      final c = open();
      await settle();
      final s = studio(c);

      expect(s.addItem(_sound), AddResult.added);
      expect(s.addItem(_sound), AddResult.duplicate);
      expect(read(c).draft.items, hasLength(1));
    });

    test('other items need no affiliation', () async {
      final c = open();
      await settle();

      expect(studio(c).addItem(_sound), AddResult.added);
    });

    test('the first venue fills in an empty place', () async {
      final c = open();
      await settle();

      studio(c).addItem(_venue);

      final d = read(c).draft;
      expect(d.city, 'Baguio');
      expect(d.state, 'Benguet');
      expect(d.country, 'Philippines');
      expect(d.lat, 16.4);
      expect(d.lng, 120.6);
    });

    test('and leaves a place the host already chose alone', () async {
      final c = open();
      await settle();
      studio(c).edit((d) => d.copyWith(city: 'Manila', country: 'Philippines'));

      studio(c).addItem(_venue);

      expect(read(c).draft.city, 'Manila');
      expect(read(c).draft.lat, isNull);
    });

    test('an item can be removed', () async {
      final c = open();
      await settle();
      studio(c)
        ..addItem(_sound)
        ..removeItem('a1');

      expect(read(c).draft.items, isEmpty);
    });

    test('the agreed price and optional flag can be changed and cleared',
        () async {
      final c = open();
      await settle();
      studio(c)
        ..addItem(_sound)
        ..updateItem('a1', agreedPrice: 4000, isOptional: true);
      expect(read(c).draft.items.single.price, 4000);
      expect(read(c).draft.items.single.isOptional, isTrue);

      studio(c).updateItem('a1', clearPrice: true);
      expect(read(c).draft.items.single.price, 5000);
      expect(read(c).draft.items.single.isOptional, isTrue);
    });

    test('totals follow the prices', () async {
      final c = open();
      await settle();
      studio(c)
        ..addItem(_venue)
        ..addItem(_sound)
        ..updateItem('a1', agreedPrice: 4000);

      expect(read(c).draft.totals.base, 54000);
    });
  });

  group('photos', () {
    test('five is the most, and a photo can be removed', () async {
      when(() => repo.uploadVenuePhoto(any())).thenAnswer(
        (_) async => const VenuePhoto(fileId: 'f', url: 'https://x.test/f'),
      );
      final c = open();
      final photo = PickedPhoto(bytes: Uint8List(1), name: 'a.jpg');

      for (var i = 0; i < 7; i++) {
        await studio(c).addPhoto(photo);
      }

      expect(read(c).draft.photos, hasLength(5));
      verify(() => repo.uploadVenuePhoto(any())).called(5);
    });

    test('a failed upload keeps the reason and leaves the draft as it was',
        () async {
      when(() => repo.uploadVenuePhoto(any()))
          .thenThrow(const ServerException('storage is down'));
      final c = open();

      await studio(c).addPhoto(PickedPhoto(bytes: Uint8List(1), name: 'a.jpg'));

      expect(read(c).draft.photos, isEmpty);
      expect(read(c).error, 'photo');
      expect(read(c).errorDetail, 'storage is down');
    });
  });

  group('the place', () {
    test(
        'country, state and city narrow down, and a country change clears them',
        () async {
      final c = open();
      await settle();
      await studio(c)
          .pickCountry(const PlaceOption(code: 'PH', name: 'Philippines'));
      expect(read(c).draft.country, 'Philippines');
      expect(read(c).cities, ['Baguio', 'Quezon City']);

      studio(c).pickCity('Baguio');
      expect(read(c).draft.city, 'Baguio');

      await studio(c)
          .pickCountry(const PlaceOption(code: 'US', name: 'United States'));
      expect(read(c).draft.city, isEmpty);
    });

    test('the phone location fills in the town and keeps the position',
        () async {
      final c = open();
      await settle();

      await studio(c).useMyLocation();

      final d = read(c).draft;
      expect(d.country, 'Philippines');
      expect(d.city, 'Quezon City');
      expect(d.lat, 14.6);
      expect(d.lng, 121.0);
    });

    test('says why when the location cannot be found', () async {
      locator.result = const LocateResult(LocateOutcome.denied);
      final c = open();
      await settle();

      await studio(c).useMyLocation();

      expect(read(c).locateProblem, 'denied');
      expect(read(c).draft.lat, isNull);
    });
  });

  group('saving', () {
    test('needs a title, even for a draft', () async {
      final c = open();
      await settle();

      expect(await studio(c).save(submit: false), SaveOutcome.blocked);
      expect(read(c).error, 'title');
      verifyNever(() => repo.createEvent(any()));
    });

    test('a draft is created, its package is synced, and nothing is submitted',
        () async {
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      expect(await studio(c).save(submit: false), SaveOutcome.saved);

      verify(() => repo.createEvent(any())).called(1);
      verify(
        () => repo.syncEventPackage('t1', any(), before: any(named: 'before')),
      ).called(1);
      verifyNever(() => repo.submitEvent(any()));
      expect(read(c).eventId, 't1');
      expect(read(c).status, 'draft');
    });

    test('saving again updates it, and never creates a second event', () async {
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      await studio(c).save(submit: false);
      await studio(c).save(submit: false);

      verify(() => repo.createEvent(any())).called(1);
      verify(() => repo.updateEvent('t1', any())).called(1);
    });

    test('sending for review saves, syncs and then submits', () async {
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      expect(await studio(c).save(submit: true), SaveOutcome.submitted);

      verifyInOrder([
        () => repo.createEvent(any()),
        () => repo.syncEventPackage('t1', any(), before: any(named: 'before')),
        () => repo.submitEvent('t1'),
      ]);
      expect(read(c).status, 'pending');
    });

    test('cannot be sent for review until it is ready', () async {
      final c = open();
      await settle();
      studio(c).edit((d) => d.copyWith(title: 'Bonfire'));

      expect(read(c).canSubmit, isFalse);
      expect(await studio(c).save(submit: true), SaveOutcome.blocked);
      verifyNever(() => repo.submitEvent(any()));
    });

    test('an event already sent or live is saved but not sent again', () async {
      when(() => repo.eventDetail('t1')).thenAnswer(
        (_) async => EventDetail(
          id: 't1',
          status: 'published',
          draft: ready(),
        ),
      );
      final c = open('t1');
      await settle();

      expect(read(c, 't1').canSubmit, isFalse);
      expect(await studio(c, 't1').save(submit: true), SaveOutcome.blocked);
      expect(await studio(c, 't1').save(submit: false), SaveOutcome.saved);

      verify(() => repo.updateEvent('t1', any())).called(1);
      verifyNever(() => repo.submitEvent(any()));
    });

    test('a refused item is reported and stops the submit', () async {
      when(
        () => repo.syncEventPackage(any(), any(), before: any(named: 'before')),
      ).thenAnswer(
        (_) async => const [
          PackageProblem('Sky Hall', 'you need an approved affiliation'),
        ],
      );
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      expect(await studio(c).save(submit: true), SaveOutcome.partial);

      verifyNever(() => repo.submitEvent(any()));
      expect(read(c).problems.single.name, 'Sky Hall');
      // The event itself was saved, so a retry updates it.
      expect(read(c).eventId, 't1');
      // What the API refused is not counted as saved.
      expect(read(c).baseline, isEmpty);
    });

    test('what the API took is remembered as saved', () async {
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      await studio(c).save(submit: false);

      expect(read(c).baseline.single.id, 'v1');
    });

    test('a refusal from the API is reported with its words', () async {
      when(() => repo.createEvent(any()))
          .thenThrow(const ServerException('Name is taken'));
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      expect(await studio(c).save(submit: false), SaveOutcome.failed);

      expect(read(c).error, 'save');
      expect(read(c).errorDetail, 'Name is taken');
      expect(read(c).saving, isFalse);
      expect(read(c).eventId, isNull);
    });

    test('a failed submit leaves the saved event a draft', () async {
      when(() => repo.submitEvent(any()))
          .thenThrow(const ServerException('Template is not in draft'));
      final c = open();
      await settle();
      studio(c).edit((_) => ready());

      expect(await studio(c).save(submit: true), SaveOutcome.failed);

      expect(read(c).status, 'draft');
      expect(read(c).errorDetail, 'Template is not in draft');
    });
  });
}
