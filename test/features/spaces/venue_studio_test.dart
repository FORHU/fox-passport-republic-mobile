import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/venue_studio_controller.dart';
import 'package:flutter_template/features/spaces/presentation/pages/venue_studio_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
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

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async =>
      PickedPhoto(bytes: Uint8List.fromList([1]), name: 'a.jpg');
}

const GeoPoint _pin = (lat: 14.5995, lng: 120.9842);

const _ready = VenueDraft(
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
  late _MockRepo repo;
  late _FakeLocator locator;

  setUpAll(() {
    registerFallbackValue(const VenueDraft());
    registerFallbackValue(PickedPhoto(bytes: Uint8List(0), name: ''));
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.neighbourBoundaries(excludeId: any(named: 'excludeId')))
        .thenAnswer((_) async => const []);
    when(() => repo.cancellationPolicies()).thenAnswer((_) async => const []);
    locator = _FakeLocator();
    when(() => repo.countries()).thenAnswer(
      (_) async => const [
        PlaceOption(code: 'PH', name: 'Philippines'),
        PlaceOption(code: 'US', name: 'United States'),
      ],
    );
    when(() => repo.states('PH')).thenAnswer(
      (_) async => const [PlaceOption(code: 'NCR', name: 'Metro Manila')],
    );
    when(() => repo.states('US')).thenAnswer((_) async => const []);
    when(() => repo.cities('PH', stateCode: 'NCR'))
        .thenAnswer((_) async => ['Manila', 'Quezon City']);
    when(() => repo.cities('US')).thenAnswer((_) async => ['Austin']);
  });

  ProviderContainer container(String? venueId) {
    final c = ProviderContainer(
      overrides: [
        spacesRepositoryProvider.overrideWithValue(repo),
        photoPickerProvider.overrideWithValue(_FakePicker()),
        deviceLocatorProvider.overrideWithValue(locator),
      ],
    );
    addTearDown(c.dispose);
    // Kept alive, as the screen would, so the controller survives the test.
    c.listen(venueStudioProvider(venueId), (_, __) {});
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('the studio controller', () {
    test('starts empty for a new venue and cannot be submitted', () async {
      final c = container(null);
      await settle();

      final state = c.read(venueStudioProvider(null));
      expect(state.loading, isFalse);
      expect(state.canSubmit, isFalse);
      expect(state.step, StudioStep.basics);
    });

    test('steps forward and back, and not past either end', () async {
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier)
        ..back()
        ..next()
        ..next();
      expect(c.read(venueStudioProvider(null)).step, StudioStep.photos);

      for (var i = 0; i < 10; i++) {
        studio.next();
      }
      expect(c.read(venueStudioProvider(null)).step, StudioStep.review);
    });

    test('loads a saved venue to edit, remembering that it is live', () async {
      when(() => repo.venueDetail('v1')).thenAnswer(
        (_) async => const VenueDetail(
          id: 'v1',
          status: 'available',
          draft: _ready,
        ),
      );
      final c = container('v1');
      expect(c.read(venueStudioProvider('v1')).loading, isTrue);
      await settle();

      final state = c.read(venueStudioProvider('v1'));
      expect(state.loading, isFalse);
      expect(state.live, isTrue);
      expect(state.draft.name, 'Sky Hall');
    });

    test('says so when the venue cannot be loaded', () async {
      when(() => repo.venueDetail('v1')).thenThrow(Exception('down'));
      final c = container('v1');
      await settle();

      final s = c.read(venueStudioProvider('v1'));
      expect(s.loadFailed, isTrue);
    });

    test('a photo that uploads is added; five is the most', () async {
      when(() => repo.uploadVenuePhoto(any())).thenAnswer(
        (_) async => const VenuePhoto(fileId: 'f2', url: 'https://x.test/2'),
      );
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier);
      final photo = PickedPhoto(bytes: Uint8List(1), name: 'a.jpg');

      for (var i = 0; i < 7; i++) {
        await studio.addPhoto(photo);
      }

      expect(c.read(venueStudioProvider(null)).draft.photos, hasLength(5));
      verify(() => repo.uploadVenuePhoto(any())).called(5);
    });

    test('a photo that fails to upload leaves the draft as it was', () async {
      when(() => repo.uploadVenuePhoto(any())).thenThrow(Exception('no'));
      final c = container(null);

      await c
          .read(venueStudioProvider(null).notifier)
          .addPhoto(PickedPhoto(bytes: Uint8List(1), name: 'a.jpg'));

      final state = c.read(venueStudioProvider(null));
      expect(state.draft.photos, isEmpty);
      expect(state.error, 'photo');
      expect(state.uploading, isFalse);
    });

    test('a pin over a neighbour is flagged and blocks submitting', () async {
      when(() => repo.neighbourBoundaries(excludeId: any(named: 'excludeId')))
          .thenAnswer(
        (_) async => [
          VenueBoundary(
            id: 'n1',
            name: 'Next Door',
            ring: circlePolygon(_pin, 300),
          ),
        ],
      );
      final c = container(null);
      await settle();
      c.read(venueStudioProvider(null).notifier).edit((_) => _ready);

      final state = c.read(venueStudioProvider(null));
      expect(state.overlapping, ['Next Door']);
      expect(state.canSubmit, isFalse);
      expect(
        await c.read(venueStudioProvider(null).notifier).save(submit: true),
        isFalse,
      );
      verifyNever(() => repo.createVenue(any(), submit: any(named: 'submit')));
    });

    test('moving the pin away clears the overlap', () async {
      when(() => repo.neighbourBoundaries(excludeId: any(named: 'excludeId')))
          .thenAnswer(
        (_) async => [
          VenueBoundary(
            id: 'n1',
            name: 'Next Door',
            ring: circlePolygon(_pin, 300),
          ),
        ],
      );
      final c = container(null);
      await settle();
      final studio = c.read(venueStudioProvider(null).notifier)
        ..edit((_) => _ready)
        ..edit((d) => d.copyWith(center: (lat: 14.8, lng: 121.3)));

      expect(c.read(venueStudioProvider(null)).overlapping, isEmpty);
      expect(c.read(venueStudioProvider(null)).canSubmit, isTrue);
      expect(studio, isNotNull);
    });

    test('saves a new venue as a draft or for review', () async {
      when(() => repo.createVenue(any(), submit: any(named: 'submit')))
          .thenAnswer((_) async => 'v9');
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier)
        ..edit((_) => _ready);

      expect(await studio.save(submit: false), isTrue);
      expect(await studio.save(submit: true), isTrue);

      verifyInOrder([
        () => repo.createVenue(any(), submit: false),
        () => repo.createVenue(any(), submit: true),
      ]);
    });

    test('a draft with gaps can be saved but not submitted', () async {
      when(() => repo.createVenue(any(), submit: any(named: 'submit')))
          .thenAnswer((_) async => 'v9');
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier);

      expect(await studio.save(submit: true), isFalse);
      expect(await studio.save(submit: false), isTrue);
    });

    test('editing a live venue keeps it live', () async {
      when(() => repo.venueDetail('v1')).thenAnswer(
        (_) async =>
            const VenueDetail(id: 'v1', status: 'available', draft: _ready),
      );
      when(
        () => repo.updateVenue(
          any(),
          any(),
          live: any(named: 'live'),
          submit: any(named: 'submit'),
        ),
      ).thenAnswer((_) async {});
      final c = container('v1');
      await settle();

      await c.read(venueStudioProvider('v1').notifier).save(submit: true);

      verify(
        () => repo.updateVenue('v1', any(), live: true, submit: true),
      ).called(1);
    });

    test('tells an overlap refused by the API from any other failure',
        () async {
      when(() => repo.createVenue(any(), submit: any(named: 'submit')))
          .thenThrow(Exception('Boundary overlaps an existing venue'));
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier);

      expect(await studio.save(submit: false), isFalse);
      expect(c.read(venueStudioProvider(null)).error, 'overlap');
      expect(c.read(venueStudioProvider(null)).saving, isFalse);
    });
  });

  group('the place of a venue', () {
    test('lists countries, and narrows to states and then cities', () async {
      final c = container(null);
      await settle();
      expect(
        c.read(venueStudioProvider(null)).countries.map((p) => p.name),
        ['Philippines', 'United States'],
      );

      final studio = c.read(venueStudioProvider(null).notifier);
      await studio.pickCountry(
        const PlaceOption(code: 'PH', name: 'Philippines'),
      );
      var state = c.read(venueStudioProvider(null));
      expect(state.draft.country, 'Philippines');
      expect(state.states.map((s) => s.name), ['Metro Manila']);
      // A country with states waits for one before listing cities.
      expect(state.cities, isEmpty);

      await studio.pickState(
        const PlaceOption(code: 'NCR', name: 'Metro Manila'),
      );
      state = c.read(venueStudioProvider(null));
      expect(state.draft.state, 'Metro Manila');
      expect(state.cities, ['Manila', 'Quezon City']);
    });

    test('a country without states lists its cities straight away', () async {
      final c = container(null);
      await settle();

      await c
          .read(venueStudioProvider(null).notifier)
          .pickCountry(const PlaceOption(code: 'US', name: 'United States'));

      expect(c.read(venueStudioProvider(null)).cities, ['Austin']);
    });

    test('changing the country clears the state and city', () async {
      final c = container(null);
      await settle();
      final studio = c.read(venueStudioProvider(null).notifier)
        ..edit((d) => d.copyWith(state: 'Metro Manila', city: 'Manila'));

      await studio.pickCountry(
        const PlaceOption(code: 'US', name: 'United States'),
      );

      final draft = c.read(venueStudioProvider(null)).draft;
      expect(draft.state, isEmpty);
      expect(draft.city, isEmpty);
    });

    test('a saved venue opens with its dropdowns narrowed down', () async {
      when(() => repo.venueDetail('v1')).thenAnswer(
        (_) async => VenueDetail(
          id: 'v1',
          status: 'draft',
          draft: _ready.copyWith(
            country: 'Philippines',
            state: 'Metro Manila',
            city: 'Manila',
          ),
        ),
      );
      final c = container('v1');
      await settle();
      await settle();

      final state = c.read(venueStudioProvider('v1'));
      expect(state.countryCode, 'PH');
      expect(state.stateCode, 'NCR');
      expect(state.cities, contains('Manila'));
    });

    test('the lists failing leaves the venue editable', () async {
      when(() => repo.countries()).thenThrow(Exception('down'));
      final c = container(null);
      await settle();

      expect(c.read(venueStudioProvider(null)).countries, isEmpty);
      c.read(venueStudioProvider(null).notifier).pickCity('Cebu');
      expect(c.read(venueStudioProvider(null)).draft.city, 'Cebu');
    });
  });

  group('using the phone location', () {
    test('drops the pin and fills in the country and city', () async {
      final c = container(null);
      await settle();

      await c.read(venueStudioProvider(null).notifier).useMyLocation();

      final state = c.read(venueStudioProvider(null));
      expect(state.draft.center, (lat: 14.6, lng: 121.0));
      expect(state.draft.country, 'Philippines');
      expect(state.draft.city, 'Quezon City');
      expect(state.locating, isFalse);
      expect(state.locateProblem, isNull);
    });

    test('still drops the pin when the town cannot be worked out', () async {
      locator.place = const DevicePlace();
      final c = container(null);
      await settle();

      await c.read(venueStudioProvider(null).notifier).useMyLocation();

      final state = c.read(venueStudioProvider(null));
      expect(state.draft.center, isNotNull);
      expect(state.draft.city, isEmpty);
    });

    test('says why when location is refused, off or failing', () async {
      final c = container(null);
      await settle();
      final studio = c.read(venueStudioProvider(null).notifier);

      locator.result = const LocateResult(LocateOutcome.denied);
      await studio.useMyLocation();
      expect(c.read(venueStudioProvider(null)).locateProblem, 'denied');

      locator.result = const LocateResult(LocateOutcome.serviceOff);
      await studio.useMyLocation();
      expect(c.read(venueStudioProvider(null)).locateProblem, 'off');

      locator.result = const LocateResult(LocateOutcome.failed);
      await studio.useMyLocation();
      final state = c.read(venueStudioProvider(null));
      expect(state.locateProblem, 'failed');
      expect(state.draft.center, isNull);
      expect(state.locating, isFalse);
    });
  });

  group('a photo that will not upload', () {
    test('keeps the reason the server gave', () async {
      when(() => repo.uploadVenuePhoto(any())).thenThrow(
        const ServerException('The storage keys are wrong'),
      );
      final c = container(null);

      await c
          .read(venueStudioProvider(null).notifier)
          .addPhoto(PickedPhoto(bytes: Uint8List(1), name: 'a.jpg'));

      final state = c.read(venueStudioProvider(null));
      expect(state.error, 'photo');
      expect(state.errorDetail, 'The storage keys are wrong');
    });
  });

  group('the studio screen', () {
    Future<void> pump(WidgetTester tester, {String? venueId}) async {
      tester.view
        ..physicalSize = const Size(900, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spacesRepositoryProvider.overrideWithValue(repo),
            photoPickerProvider.overrideWithValue(_FakePicker()),
            deviceLocatorProvider.overrideWithValue(locator),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: VenueStudioPage(venueId: venueId),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a new venue starts on the basics', (tester) async {
      await pump(tester);

      expect(find.text('New venue'), findsOneWidget);
      expect(find.text('Venue name'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('Next walks through to the review, which lists the gaps', (
      tester,
    ) async {
      await pump(tester);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }

      expect(find.text('Still to fill in'), findsOneWidget);
      expect(find.text('Venue name'), findsOneWidget);
      expect(find.text('A pin on the map'), findsOneWidget);
      expect(find.text('At least one photo'), findsOneWidget);
      expect(find.text('Save as draft'), findsOneWidget);
      final submit = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send for review'),
      );
      expect(submit.onPressed, isNull);
    });

    testWidgets('the location step offers dropdowns and the phone location', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Use my current location'), findsOneWidget);
      expect(find.byType(DropdownMenu<String>), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
      // State and city wait for a country.
      expect(find.text('City'), findsNothing);

      await tester.tap(find.text('Use my current location'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('City'), findsOneWidget);
    });

    testWidgets('typing fills the draft', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField).first, 'Sky Hall');
      await tester.pump();

      final element = tester.element(find.byType(VenueStudioPage));
      final container = ProviderScope.containerOf(element);
      expect(container.read(venueStudioProvider(null)).draft.name, 'Sky Hall');
    });

    testWidgets('a live venue shows a note and a Save changes button', (
      tester,
    ) async {
      when(() => repo.venueDetail('v1')).thenAnswer(
        (_) async =>
            const VenueDetail(id: 'v1', status: 'available', draft: _ready),
      );
      await pump(tester, venueId: 'v1');

      expect(find.text('Edit venue'), findsOneWidget);
      expect(find.textContaining('This venue is live'), findsOneWidget);
      expect(find.text('Sky Hall'), findsWidgets);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
      expect(find.text('Ready to send for review'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Save as draft'), findsNothing);
    });

    testWidgets('says so when a venue to edit will not load', (tester) async {
      when(() => repo.venueDetail('v1')).thenThrow(Exception('down'));
      await pump(tester, venueId: 'v1');

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });
}
