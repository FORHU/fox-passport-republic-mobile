import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/listing_draft.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/listing_studio_controller.dart';
import 'package:flutter_template/features/spaces/presentation/pages/listing_studio_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpacesRepository {}

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async =>
      PickedPhoto(bytes: Uint8List.fromList([1]), name: 'a.jpg');
}

class _NoLocator implements DeviceLocator {
  @override
  Future<LocateResult> locate({bool prompt = true}) async =>
      const LocateResult(LocateOutcome.denied);

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async =>
      const DevicePlace();
}

const _photo = VenuePhoto(fileId: 'f1', url: 'https://x.test/a.png');

const _service = ListingDraft(
  category: 'dj',
  name: 'Night DJ',
  description: 'Sets for any crowd',
  price: 2500,
  city: 'Manila',
  country: 'Philippines',
  willingToTravel: true,
  photos: [_photo],
);

const _gear = ListingDraft(
  category: 'sound_system',
  name: 'PA system',
  description: 'Two speakers and a mixer',
  price: 800,
  quantity: 4,
  condition: 'fair',
  photos: [_photo],
);

const ListingTarget _newService = (kind: ProviderKind.services, id: null);
const ListingTarget _newGear = (kind: ProviderKind.gear, id: null);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const ListingDraft());
    registerFallbackValue(ProviderKind.gear);
    registerFallbackValue(PickedPhoto(bytes: Uint8List(0), name: ''));
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.countries()).thenAnswer((_) async => const []);
  });

  ProviderContainer container(ListingTarget target) {
    final c = ProviderContainer(
      overrides: [
        spacesRepositoryProvider.overrideWithValue(repo),
        photoPickerProvider.overrideWithValue(_FakePicker()),
        deviceLocatorProvider.overrideWithValue(_NoLocator()),
      ],
    );
    addTearDown(c.dispose);
    // Kept alive, as the screen would, so the controller survives the test.
    c.listen(listingStudioProvider(target), (_, __) {});
    return c;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('ListingDraft', () {
    test('a service is sent with its travel flag, gear with a quantity', () {
      final service = _service.toJson(ProviderKind.services, status: 'draft');
      expect(service['isWillingToTravel'], isTrue);
      expect(service.containsKey('quantity'), isFalse);
      expect(service['imgIds'], ['f1']);
      expect(service['status'], 'draft');
      expect(service['currency'], 'PHP');

      final gear = _gear.toJson(ProviderKind.gear, status: 'pending');
      expect(gear['quantity'], 4);
      expect(gear['condition'], 'fair');
      expect(gear.containsKey('isWillingToTravel'), isFalse);
      // Gear's place is optional, so it is left out when empty.
      expect(gear.containsKey('city'), isFalse);
    });

    test('an edit leaves out the photos and, when live, the status', () {
      final body = _service.toJson(ProviderKind.services, withPhotos: false);
      expect(body.containsKey('imgIds'), isFalse);
      expect(body.containsKey('status'), isFalse);
    });

    test('a service needs its town; gear does not', () {
      expect(_service.isComplete(ProviderKind.services), isTrue);
      expect(
        _service.copyWith(city: '').isComplete(ProviderKind.services),
        isFalse,
      );
      expect(_gear.isComplete(ProviderKind.gear), isTrue);
      expect(
        _gear.copyWith(photos: const []).isComplete(ProviderKind.gear),
        isFalse,
      );
      expect(const ListingDraft().isComplete(ProviderKind.gear), isFalse);
    });

    test('reads a saved listing, with its photos', () {
      final d = ListingDraft.fromJson(const {
        'category': 'sound_system',
        'name': 'PA',
        'description': 'Loud',
        'price': '800.00',
        'quantity': 2,
        'condition': 'new',
        'billingRate': 'daily',
        'city': 'Cebu',
        'images': [
          {'id': 'f9', 'url': 'https://x.test/p.png'},
          {'nope': 1},
        ],
      });

      expect(d.price, 800);
      expect(d.quantity, 2);
      expect(d.billingRate, 'daily');
      expect(d.city, 'Cebu');
      expect(d.photos.single.fileId, 'f9');
    });
  });

  group('the studio controller', () {
    test('sends a complete new service for review', () async {
      when(
        () => repo.createListing(any(), any(), submit: any(named: 'submit')),
      ).thenAnswer((_) async => 'new1');
      final c = container(_newService);
      await settle();
      final studio = c.read(listingStudioProvider(_newService).notifier)
        ..edit((_) => _service);

      final ok = await studio.save(submit: true);

      expect(ok, isTrue);
      verify(
        () => repo.createListing(ProviderKind.services, _service, submit: true),
      ).called(1);
    });

    test('will not save what is not complete', () async {
      final c = container(_newGear);
      await settle();

      final ok = await c
          .read(listingStudioProvider(_newGear).notifier)
          .save(submit: false);

      expect(ok, isFalse);
      verifyNever(
        () => repo.createListing(any(), any(), submit: any(named: 'submit')),
      );
    });

    test('says why the API refused', () async {
      when(
        () => repo.createListing(any(), any(), submit: any(named: 'submit')),
      ).thenThrow(const ServerException('You must be an approved Foxer'));
      final c = container(_newService);
      await settle();
      final studio = c.read(listingStudioProvider(_newService).notifier)
        ..edit((_) => _service);

      final ok = await studio.save(submit: false);

      expect(ok, isFalse);
      expect(
        c.read(listingStudioProvider(_newService)).errorDetail,
        'You must be an approved Foxer',
      );
    });

    test('opens a live listing to edit and keeps it live', () async {
      const ListingTarget target = (kind: ProviderKind.gear, id: 'g1');
      when(() => repo.listingDetail(ProviderKind.gear, 'g1'))
          .thenAnswer((_) async => (draft: _gear, status: 'available'));
      when(
        () => repo.updateListing(
          any(),
          any(),
          any(),
          live: any(named: 'live'),
          submit: any(named: 'submit'),
        ),
      ).thenAnswer((_) async {});
      final c = container(target);
      await settle();
      await settle();

      final state = c.read(listingStudioProvider(target));
      expect(state.live, isTrue);
      expect(state.draft.name, 'PA system');

      await c.read(listingStudioProvider(target).notifier).save(submit: true);
      verify(
        () => repo.updateListing(
          ProviderKind.gear,
          'g1',
          _gear,
          live: true,
          submit: true,
        ),
      ).called(1);
    });

    test('adds an uploaded photo', () async {
      when(() => repo.uploadVenuePhoto(any())).thenAnswer((_) async => _photo);
      final c = container(_newGear);
      await settle();

      await c
          .read(listingStudioProvider(_newGear).notifier)
          .addPhoto(PickedPhoto(bytes: Uint8List(1), name: 'a.jpg'));

      final photos = c.read(listingStudioProvider(_newGear)).draft.photos;
      expect(photos, hasLength(1));
    });
  });

  group('the form', () {
    Future<void> open(
      WidgetTester tester,
      ListingStudioPage page, {
      List<String> roles = const ['serviceFoxer'],
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            spacesRepositoryProvider.overrideWithValue(repo),
            photoPickerProvider.overrideWithValue(_FakePicker()),
            deviceLocatorProvider.overrideWithValue(_NoLocator()),
            heldRolesProvider.overrideWithValue(roles),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: page,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('gear asks how many and in what condition', (tester) async {
      await open(tester, const ListingStudioPage(kind: ProviderKind.gear));

      expect(find.text('Add gear'), findsOneWidget);
      expect(find.text('How many do you have?'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('I will travel to the event'), findsNothing);
    });

    testWidgets('a service asks whether you travel, not how many', (
      tester,
    ) async {
      await open(tester, const ListingStudioPage(kind: ProviderKind.services));

      expect(find.text('Add a service'), findsOneWidget);
      expect(find.text('I will travel to the event'), findsOneWidget);
      expect(find.text('How many do you have?'), findsNothing);
    });

    testWidgets('Submit waits until the listing is complete', (tester) async {
      await open(tester, const ListingStudioPage(kind: ProviderKind.gear));

      final button = find.widgetWithText(ElevatedButton, 'Send for review');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    });

    testWidgets('fits a narrow screen', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, const ListingStudioPage(kind: ProviderKind.gear));

      expect(tester.takeException(), isNull);
    });
  });
}
