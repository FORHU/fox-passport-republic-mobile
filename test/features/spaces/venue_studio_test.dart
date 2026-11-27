import 'dart:async';
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
import 'package:flutter_template/theme/app_theme.dart';
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
  state: 'Metro Manila',
  district: 'Ermita',
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

    test('leaving the screen while a venue loads does not crash', () async {
      final loaded = Completer<VenueDetail>();
      when(() => repo.venueDetail('v1')).thenAnswer((_) => loaded.future);
      final c = container('v1');
      await settle();

      // The host backs out before the answer arrives.
      c.dispose();
      loaded.complete(
        const VenueDetail(id: 'v1', status: 'available', draft: _ready),
      );
      await settle();
      await settle();
    });

    test('steps forward and back, and not past either end', () async {
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier)
        ..edit((_) => _ready)
        ..back()
        ..next()
        ..next();
      expect(c.read(venueStudioProvider(null)).step, StudioStep.photos);

      for (var i = 0; i < 10; i++) {
        studio.next();
      }
      expect(c.read(venueStudioProvider(null)).step, StudioStep.review);
    });

    test('Next stops on a step that lacks something, and says so', () async {
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier)..next();

      var state = c.read(venueStudioProvider(null));
      expect(state.step, StudioStep.basics);
      expect(state.showErrors, isTrue);
      expect(
        state.missingIn(StudioStep.basics),
        ['name', 'category', 'description', 'capacity'],
      );

      // Filling the step in lets it go on, with the flags cleared.
      studio
        ..edit(
          (d) => d.copyWith(
            name: 'Sky Hall',
            category: 'indoor',
            description: 'A hall',
            capacity: 100,
          ),
        )
        ..next();
      state = c.read(venueStudioProvider(null));
      expect(state.step, StudioStep.location);
      expect(state.showErrors, isFalse);
    });

    test('the header cannot jump past an incomplete step, but back is free',
        () async {
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier)
        ..goTo(StudioStep.pricing);
      expect(c.read(venueStudioProvider(null)).step, StudioStep.basics);

      studio
        ..edit((_) => _ready)
        ..goTo(StudioStep.pricing);
      expect(c.read(venueStudioProvider(null)).step, StudioStep.pricing);

      studio.goTo(StudioStep.basics);
      expect(c.read(venueStudioProvider(null)).step, StudioStep.basics);
      expect(c.read(venueStudioProvider(null)).showErrors, isFalse);
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

  // mobile#506: the days the venue is closed, chosen while creating it.
  group('availability', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inThree = today.add(const Duration(days: 3));
    final inFive = today.add(const Duration(days: 5));
    final yesterday = today.subtract(const Duration(days: 1));

    test('a new venue keeps closed days in the draft, in order', () async {
      final c = container(null);
      final studio = c.read(venueStudioProvider(null).notifier);

      await studio.toggleDay(inFive);
      await studio.toggleDay(inThree);
      expect(c.read(venueStudioProvider(null)).draft.closedDays, [
        inThree,
        inFive,
      ]);

      // Again opens it; a past day is left alone.
      await studio.toggleDay(inFive);
      await studio.toggleDay(yesterday);
      expect(c.read(venueStudioProvider(null)).draft.closedDays, [inThree]);
      expect(c.read(venueStudioProvider(null)).closedDays, {inThree});
      verifyNever(() => repo.blockDay(any(), any()));
    });

    test('they go with the venue as blockedDates, and only when chosen', () {
      final key = dayKey(inThree);
      expect(
        _ready.copyWith(closedDays: [inThree]).toJson()['blockedDates'],
        [key],
      );
      expect(_ready.toJson().containsKey('blockedDates'), isFalse);
      expect(dayKey(DateTime(2027, 3, 4)), '2027-03-04');
    });

    group('a saved venue', () {
      setUpAll(() => registerFallbackValue(DateTime(2000)));

      setUp(() {
        when(() => repo.venueDetail('v1')).thenAnswer(
          (_) async =>
              const VenueDetail(id: 'v1', status: 'available', draft: _ready),
        );
        when(() => repo.venueDays('v1', any())).thenAnswer(
          (_) async => (booked: {inFive}, closed: <DateTime>{}),
        );
      });

      test('shows its booked days and closes a day at once', () async {
        when(() => repo.blockDay('v1', any())).thenAnswer((_) async {});
        when(() => repo.unblockDay('v1', any())).thenAnswer((_) async {});
        final c = container('v1');
        await settle();
        await settle();
        final studio = c.read(venueStudioProvider('v1').notifier);
        expect(c.read(venueStudioProvider('v1')).bookedDays, {inFive});

        await studio.toggleDay(inThree);
        verify(() => repo.blockDay('v1', inThree)).called(1);
        expect(c.read(venueStudioProvider('v1')).closedDays, {inThree});
        // Never sent with the venue, so saving can't replace them.
        expect(c.read(venueStudioProvider('v1')).draft.closedDays, isEmpty);

        await studio.toggleDay(inThree);
        verify(() => repo.unblockDay('v1', inThree)).called(1);
        expect(c.read(venueStudioProvider('v1')).closedDays, isEmpty);

        // A booked day stays as it is.
        await studio.toggleDay(inFive);
        verifyNever(() => repo.blockDay('v1', inFive));
      });

      test('a day that will not close goes back and says so', () async {
        when(() => repo.blockDay('v1', any())).thenThrow(Exception('down'));
        final c = container('v1');
        await settle();
        await settle();

        await c.read(venueStudioProvider('v1').notifier).toggleDay(inThree);

        final s = c.read(venueStudioProvider('v1'));
        expect(s.closedDays, isEmpty);
        expect(s.daysFailed, isTrue);
      });
    });

    testWidgets('the Availability step closes a day with a tap', (
      tester,
    ) async {
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
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const VenueStudioPage(),
          ),
        ),
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(VenueStudioPage)),
      );
      container.read(venueStudioProvider(null).notifier)
        ..edit((_) => _ready)
        ..goTo(StudioStep.availability);
      await tester.pump();

      expect(find.text('Availability'), findsWidgets);
      expect(find.text('No days closed'), findsOneWidget);

      // The day after tomorrow, on whichever month it falls.
      final day = today.add(const Duration(days: 2));
      if (day.month != today.month) {
        await tester.tap(find.byTooltip('Next month'));
        await tester.pump();
      }
      await tester.tap(find.byKey(Key('day-${dayKey(day)}')));
      await tester.pump();

      expect(find.text('1 day closed'), findsOneWidget);
      expect(
        container.read(venueStudioProvider(null)).draft.closedDays,
        [day],
      );
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
            // The real theme: its buttons are as wide as their parent unless
            // told otherwise, which a plain theme would hide.
            theme: AppTheme.dark,
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
      // Required fields carry an asterisk, and nothing is flagged yet.
      expect(find.text('Venue name *'), findsOneWidget);
      expect(find.text('Required'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets('Next on an empty step stays, flags and lists the gaps', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('New venue'), findsOneWidget);
      expect(find.text('Venue name *'), findsOneWidget);
      // Name, description and capacity, and the type of venue.
      expect(find.text('Required'), findsNWidgets(4));
      expect(
        find.text(
          'Fill in to continue: Venue name, Type of venue, Description, '
          'Capacity',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Next walks through a complete venue to the review', (
      tester,
    ) async {
      await pump(tester);
      final element = tester.element(find.byType(VenueStudioPage));
      ProviderScope.containerOf(element)
          .read(venueStudioProvider(null).notifier)
          .edit((_) => _ready);
      await tester.pump();

      for (var i = 0; i < StudioStep.values.length - 1; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }

      expect(find.text('Ready to send for review'), findsOneWidget);
      expect(find.text('Save as draft'), findsOneWidget);
      final submit = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send for review'),
      );
      expect(submit.onPressed, isNotNull);
    });

    testWidgets('the location step offers dropdowns and the phone location', (
      tester,
    ) async {
      await pump(tester);
      final element = tester.element(find.byType(VenueStudioPage));
      ProviderScope.containerOf(element)
          .read(venueStudioProvider(null).notifier)
          .edit(
            (d) => d.copyWith(
              name: 'Sky Hall',
              category: 'indoor',
              description: 'A hall',
              capacity: 100,
            ),
          );
      await tester.pump();
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

      for (var i = 0; i < StudioStep.values.length - 1; i++) {
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
