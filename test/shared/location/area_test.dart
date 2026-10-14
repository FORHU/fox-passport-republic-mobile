import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

class _FakeLocator implements DeviceLocator {
  _FakeLocator(this.result, {this.city});

  final LocateResult result;
  final String? city;
  final prompted = <bool>[];

  @override
  Future<LocateResult> locate({bool prompt = true}) async {
    prompted.add(prompt);
    return result;
  }

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async =>
      DevicePlace(city: city);
}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.getString(any())).thenReturn(null);
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});
  });

  ProviderContainer container(_FakeLocator locator, {String? profileCity}) {
    final c = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        deviceLocatorProvider.overrideWithValue(locator),
        profileCityProvider.overrideWith((ref) async => profileCity),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts on the profile city and asks for nothing', () async {
    final locator = _FakeLocator(const LocateResult(LocateOutcome.denied));
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    final filter = c.read(areaFilterProvider);

    expect(filter.city, 'Baguio');
    expect(filter.hasPoint, isFalse);
    expect(locator.prompted, isEmpty);
  });

  test('using the device keeps the position and the city it is in', () async {
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 7.19, lng: 125.45),
      city: 'Davao City',
    );
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    final outcome = await c.read(areaProvider.notifier).useDevice();

    expect(outcome, LocateOutcome.ok);
    final filter = c.read(areaFilterProvider);
    expect(filter.lat, 7.19);
    expect(filter.lng, 125.45);
    expect(filter.city, 'Davao City');
    verify(() => storage.setString('area.source', 'device')).called(1);
  });

  test('a refused permission leaves the area as it was', () async {
    final locator = _FakeLocator(const LocateResult(LocateOutcome.denied));
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    final outcome = await c.read(areaProvider.notifier).useDevice();

    expect(outcome, LocateOutcome.denied);
    expect(c.read(areaFilterProvider).city, 'Baguio');
    expect(c.read(areaFilterProvider).hasPoint, isFalse);
  });

  test('a position with no city name falls back to the profile city', () async {
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 1, lng: 2),
    );
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    await c.read(areaProvider.notifier).useDevice();

    expect(c.read(areaFilterProvider).city, 'Baguio');
    expect(c.read(areaFilterProvider).hasPoint, isTrue);
  });

  test('a typed city wins over the profile and is remembered', () async {
    final locator = _FakeLocator(const LocateResult(LocateOutcome.denied));
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    await c.read(areaProvider.notifier).useCity('  Cebu City ');

    expect(c.read(areaFilterProvider).city, 'Cebu City');
    verify(() => storage.setString('area.city', 'Cebu City')).called(1);
    verify(() => storage.setString('area.source', 'manual')).called(1);
  });

  test('with no saved choice it uses the device when already allowed',
      () async {
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 7.19, lng: 125.45),
      city: 'Davao City',
    );
    final c = container(locator, profileCity: 'Baguio')..read(areaProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(locator.prompted, [false], reason: 'it must never open a dialog');
    expect(c.read(areaProvider).source, AreaSource.device);
    expect(c.read(areaFilterProvider).label, 'Davao City');
  });

  test('a position whose city is unknown is not labelled with the profile',
      () async {
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 7.19, lng: 125.45),
    );
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    await c.read(areaProvider.notifier).useDevice();

    final filter = c.read(areaFilterProvider);
    expect(filter.label, isNull);
    expect(filter.city, 'Baguio', reason: 'still used to search');
  });

  test('a manual choice is not replaced by the device', () async {
    when(() => storage.getString('area.source')).thenReturn('manual');
    when(() => storage.getString('area.city')).thenReturn('Cebu City');
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 7.19, lng: 125.45),
      city: 'Davao City',
    );
    final c = container(locator, profileCity: 'Baguio')..read(areaProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(locator.prompted, isEmpty);
    expect(c.read(areaFilterProvider).label, 'Cebu City');
  });

  test('a saved device choice is refreshed quietly, without a prompt',
      () async {
    when(() => storage.getString('area.source')).thenReturn('device');
    final locator = _FakeLocator(
      const LocateResult(LocateOutcome.ok, lat: 7, lng: 125),
      city: 'Davao City',
    );
    final c = container(locator, profileCity: 'Baguio')..read(areaProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(locator.prompted, [false]);
    expect(c.read(areaProvider).lat, 7);
  });

  test('a saved device choice falls back when the permission is gone',
      () async {
    when(() => storage.getString('area.source')).thenReturn('device');
    final locator = _FakeLocator(const LocateResult(LocateOutcome.denied));
    final c = container(locator, profileCity: 'Baguio');
    await c.read(profileCityProvider.future);

    c.read(areaProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(areaProvider).source, AreaSource.profile);
    expect(c.read(areaFilterProvider).city, 'Baguio');
  });
}
