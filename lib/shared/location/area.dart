import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/location/device_locator.dart';

/// Where "near you" is measured from.
enum AreaSource {
  /// The city saved on the user's profile (the default; asks for nothing).
  profile,

  /// The device's position, after the user chose to share it.
  device,

  /// A city the user typed.
  manual,
}

/// The user's chosen area, before the profile city is filled in.
class Area extends Equatable {
  const Area({
    this.source = AreaSource.profile,
    this.manualCity,
    this.lat,
    this.lng,
    this.deviceCity,
    this.deviceCountry,
  });

  final AreaSource source;
  final String? manualCity;
  final double? lat;
  final double? lng;

  /// The city the device position falls in, when it could be worked out.
  final String? deviceCity;

  /// ISO code of the country the device position falls in, when known.
  final String? deviceCountry;

  @override
  List<Object?> get props =>
      [source, manualCity, lat, lng, deviceCity, deviceCountry];
}

/// What the catalog needs to narrow results to the user's area.
class AreaFilter extends Equatable {
  const AreaFilter({this.city, this.lat, this.lng, this.label});

  /// The city to search by, which may be the profile's as a fallback.
  final String? city;

  /// The place to show the user. For a device position this is only the city
  /// the device is in, never the profile's, so "current location" is not
  /// mislabelled; null means the name could not be worked out.
  final String? label;
  final double? lat;
  final double? lng;

  bool get hasPoint => lat != null && lng != null;
  bool get isEmpty => city == null && !hasPoint;

  @override
  List<Object?> get props => [city, lat, lng, label];
}

const _sourceKey = 'area.source';
const _cityKey = 'area.city';

class AreaController extends Notifier<Area> {
  @override
  Area build() {
    // A saved choice that cannot be read means "no choice": the profile city.
    String? savedSource;
    String? city;
    try {
      final storage = ref.read(storageServiceProvider);
      savedSource = storage.getString(_sourceKey);
      city = storage.getString(_cityKey);
    } on Object {
      savedSource = null;
    }
    final source = AreaSource.values.firstWhere(
      (s) => s.name == savedSource,
      orElse: () => AreaSource.profile,
    );
    if (source == AreaSource.device) {
      // Re-find the device quietly; if the permission is gone, fall back.
      unawaited(Future.microtask(() => _refreshDevice(prompt: false)));
    } else if (savedSource == null) {
      // No choice yet: use where the device is when that is already allowed.
      // It never opens a permission dialog; the one-time prompt does that.
      unawaited(Future.microtask(_adoptDevice));
    }
    return Area(source: source, manualCity: city);
  }

  Future<void> _adoptDevice() async {
    final locator = ref.read(deviceLocatorProvider);
    final found = await locator.locate(prompt: false);
    // A choice made in the meantime wins.
    if (!found.isOk || state.source != AreaSource.profile) return;
    final place = await locator.placeAt(found.lat!, found.lng!);
    if (state.source != AreaSource.profile) return;
    state = Area(
      source: AreaSource.device,
      manualCity: state.manualCity,
      lat: found.lat,
      lng: found.lng,
      deviceCity: place.city,
      deviceCountry: place.countryCode,
    );
  }

  Future<void> _refreshDevice({required bool prompt}) async {
    final locator = ref.read(deviceLocatorProvider);
    final found = await locator.locate(prompt: prompt);
    if (!found.isOk) {
      if (state.source == AreaSource.device) {
        state = Area(manualCity: state.manualCity);
      }
      return;
    }
    final place = await locator.placeAt(found.lat!, found.lng!);
    state = Area(
      source: AreaSource.device,
      manualCity: state.manualCity,
      lat: found.lat,
      lng: found.lng,
      deviceCity: place.city,
      deviceCountry: place.countryCode,
    );
  }

  /// Uses the device position. Asks for permission if needed and returns why
  /// it could not, so the screen can say so.
  Future<LocateOutcome> useDevice() async {
    final locator = ref.read(deviceLocatorProvider);
    final found = await locator.locate();
    if (!found.isOk) return found.outcome;
    final place = await locator.placeAt(found.lat!, found.lng!);
    state = Area(
      source: AreaSource.device,
      manualCity: state.manualCity,
      lat: found.lat,
      lng: found.lng,
      deviceCity: place.city,
      deviceCountry: place.countryCode,
    );
    await ref
        .read(storageServiceProvider)
        .setString(_sourceKey, AreaSource.device.name);
    return LocateOutcome.ok;
  }

  Future<void> useProfile() async {
    state = Area(manualCity: state.manualCity);
    await ref
        .read(storageServiceProvider)
        .setString(_sourceKey, AreaSource.profile.name);
  }

  Future<void> useCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    state = Area(source: AreaSource.manual, manualCity: trimmed);
    final storage = ref.read(storageServiceProvider);
    await storage.setString(_sourceKey, AreaSource.manual.name);
    await storage.setString(_cityKey, trimmed);
  }
}

final areaProvider = NotifierProvider<AreaController, Area>(
  AreaController.new,
);

/// What the profile says about where the user is and what they pay in.
class ProfileLocation extends Equatable {
  const ProfileLocation({this.city, this.country, this.preferredCurrency});

  final String? city;

  /// As saved: an ISO code or a country name.
  final String? country;
  final String? preferredCurrency;

  @override
  List<Object?> get props => [city, country, preferredCurrency];
}

/// The location fields of the signed-in user's profile, or an empty one when
/// signed out or when the profile cannot be read.
final FutureProvider<ProfileLocation> profileLocationProvider =
    FutureProvider<ProfileLocation>((ref) async {
  try {
    final signedIn = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    if (!signedIn) return const ProfileLocation();
    final body = await ref.watch(apiServiceProvider).get(ApiEndpoints.profile);
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) return const ProfileLocation();
    String? text(String key) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return ProfileLocation(
      city: text('city'),
      country: text('country'),
      preferredCurrency: text('preferredCurrency'),
    );
  } on Object {
    return const ProfileLocation();
  }
});

/// The city saved on the user's profile, or null when there is none or the
/// profile cannot be read.
final FutureProvider<String?> profileCityProvider =
    FutureProvider<String?>((ref) async {
  final profile = await ref.watch(profileLocationProvider.future);
  return profile.city;
});

/// What to narrow venues and Foxers to, combining the choice with the
/// profile city.
final areaFilterProvider = Provider<AreaFilter>((ref) {
  final area = ref.watch(areaProvider);
  final profileCity = ref.watch(profileCityProvider).value;
  return switch (area.source) {
    AreaSource.device when area.lat != null && area.lng != null => AreaFilter(
        city: area.deviceCity ?? profileCity,
        lat: area.lat,
        lng: area.lng,
        label: area.deviceCity,
      ),
    AreaSource.manual when area.manualCity != null => AreaFilter(
        city: area.manualCity,
        label: area.manualCity,
      ),
    _ => AreaFilter(city: profileCity, label: profileCity),
  };
});
