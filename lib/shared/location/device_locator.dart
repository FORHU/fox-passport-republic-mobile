import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocateOutcome { ok, denied, serviceOff, failed }

/// Where the device is, or why it could not be found.
class LocateResult {
  const LocateResult(this.outcome, {this.lat, this.lng});

  final LocateOutcome outcome;
  final double? lat;
  final double? lng;

  bool get isOk => outcome == LocateOutcome.ok && lat != null && lng != null;
}

/// The town or city, and the country, at a position.
class DevicePlace {
  const DevicePlace({this.city, this.countryCode});

  final String? city;

  /// ISO 3166 alpha-2, such as `PH`.
  final String? countryCode;
}

/// Reads the device position. An interface so tests need no platform.
abstract class DeviceLocator {
  /// With [prompt] false, only an already-granted permission is used, so it
  /// never opens a system dialog.
  Future<LocateResult> locate({bool prompt = true});

  /// What is known about a coordinate; empty when it cannot be worked out.
  Future<DevicePlace> placeAt(double lat, double lng);
}

class GeolocatorDeviceLocator implements DeviceLocator {
  @override
  Future<LocateResult> locate({bool prompt = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocateResult(LocateOutcome.serviceOff);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocateResult(LocateOutcome.denied);
      }
      // Approximate is enough to find the city, and is quicker and gentler on
      // the battery than a GPS fix.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocateResult(
        LocateOutcome.ok,
        lat: position.latitude,
        lng: position.longitude,
      );
    } on Object {
      return const LocateResult(LocateOutcome.failed);
    }
  }

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async {
    // The phone's own geocoder first; the web build has none, and some
    // devices return nothing, so Mapbox (the app already has a token for the
    // globe) answers when it does not.
    final native = kIsWeb ? const DevicePlace() : await _native(lat, lng);
    if (native.city != null && native.countryCode != null) return native;
    final mapbox = await _mapbox(lat, lng);
    return DevicePlace(
      city: native.city ?? mapbox.city,
      countryCode: native.countryCode ?? mapbox.countryCode,
    );
  }

  Future<DevicePlace> _native(double lat, double lng) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(lat, lng);
      String? city;
      String? country;
      for (final mark in marks) {
        city ??= _clean(mark.locality) ?? _clean(mark.subAdministrativeArea);
        country ??= _clean(mark.isoCountryCode);
      }
      return DevicePlace(city: city, countryCode: country);
    } on Object {
      return const DevicePlace();
    }
  }

  Future<DevicePlace> _mapbox(double lat, double lng) async {
    final token = AppConfig.instance.mapboxToken;
    if (token.isEmpty) return const DevicePlace();
    try {
      final response = await Dio().get<dynamic>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json',
        queryParameters: {
          'types': 'place',
          'limit': 1,
          'access_token': token,
        },
        options: Options(receiveTimeout: const Duration(seconds: 6)),
      );
      final data = response.data;
      final features = data is Map ? data['features'] : null;
      if (features is! List || features.isEmpty) return const DevicePlace();
      final feature = features.first;
      if (feature is! Map) return const DevicePlace();
      String? country;
      final context = feature['context'];
      if (context is List) {
        for (final entry in context) {
          if (entry is Map && '${entry['id']}'.startsWith('country')) {
            country = _clean(entry['short_code'] as String?)?.toUpperCase();
          }
        }
      }
      return DevicePlace(
        city: _clean(feature['text'] as String?),
        countryCode: country,
      );
    } on Object {
      return const DevicePlace();
    }
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final deviceLocatorProvider =
    Provider<DeviceLocator>((ref) => GeolocatorDeviceLocator());
