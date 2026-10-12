import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/onboarding/domain/entities/onboarding_models.dart';

/// Talks to the API for everything onboarding needs. Knows nothing about UI.
abstract class OnboardingRemoteDataSource {
  Future<ProfileSeed> fetchProfile();
  Future<void> updateProfile({
    required String name,
    required String country,
    required String state,
    required String city,
    required String district,
  });
  Future<List<RoleRequestSummary>> fetchMyRoleRequests();
  Future<List<GeoCountry>> fetchCountries();
  Future<List<GeoState>> fetchStates(String countryCode);
  Future<List<String>> fetchCities(String countryCode, {String? stateCode});
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  OnboardingRemoteDataSourceImpl(this._api);

  final ApiService _api;

  /// Pulls `data` (a list) out of the API's `{ success, data }` envelope.
  List<dynamic> _list(dynamic body) {
    final data = body is Map ? body['data'] : null;
    return data is List ? data : const [];
  }

  List<Map<String, dynamic>> _maps(dynamic body) => [
        for (final e in _list(body))
          if (e is Map) e.cast<String, dynamic>(),
      ];

  @override
  Future<ProfileSeed> fetchProfile() async {
    final body = await _api.get(ApiEndpoints.profile);
    return ProfileSeed.fromJson((body as Map).cast<String, dynamic>());
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String country,
    required String state,
    required String city,
    required String district,
  }) async {
    await _api.put(ApiEndpoints.profile, {
      'name': name,
      'country': country,
      'state': state,
      'city': city,
      'district': district,
    });
  }

  @override
  Future<List<RoleRequestSummary>> fetchMyRoleRequests() async {
    final body = await _api.get(ApiEndpoints.roleRequestsMine);
    return _maps(body).map(RoleRequestSummary.fromJson).toList();
  }

  @override
  Future<List<GeoCountry>> fetchCountries() async {
    final body = await _api.get(ApiEndpoints.locationCountries);
    return _maps(body).map(GeoCountry.fromJson).toList();
  }

  @override
  Future<List<GeoState>> fetchStates(String countryCode) async {
    final body = await _api.get(ApiEndpoints.locationStates(countryCode));
    return _maps(body).map(GeoState.fromJson).toList();
  }

  @override
  Future<List<String>> fetchCities(
    String countryCode, {
    String? stateCode,
  }) async {
    final body = await _api.get(
      ApiEndpoints.locationCities(countryCode),
      query: stateCode == null ? null : {'state': stateCode},
    );
    return _list(body).map((e) => e.toString()).toList();
  }
}
