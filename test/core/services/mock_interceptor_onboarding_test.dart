import 'package:dio/dio.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/interceptors/mock_interceptor.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageService extends Mock implements StorageService {}

void main() {
  late Dio dio;

  setUp(() {
    AppConfig.instance = const AppConfig.dev();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:6002/api/v1'));
    dio.interceptors.add(MockInterceptor());
  });

  tearDown(() {
    dio.close(force: true);
  });

  test('serves profile and role request data for onboarding', () async {
    final profile = await dio.get<dynamic>(ApiEndpoints.profile);
    final requests = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.roleRequestsMine,
    );

    expect(profile.data, containsPair('name', 'Ada Lovelace'));
    expect(profile.data, containsPair('country', ''));
    expect(requests.data!['data'], isEmpty);
  });

  test('supports cascading location selection', () async {
    final countries = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.locationCountries,
    );
    final states = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.locationStates('PH'),
    );
    final cities = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.locationCities('PH'),
      queryParameters: {'state': 'NCR'},
    );

    expect(countries.data!['data'], contains(containsPair('code', 'PH')));
    expect(states.data!['data'], contains(containsPair('code', 'NCR')));
    expect(cities.data!['data'], contains('Quezon City'));
  });

  test('accepts profile updates from the onboarding form', () async {
    final response = await dio.put<Map<String, dynamic>>(
      ApiEndpoints.profile,
      data: {
        'name': 'Ada Lovelace',
        'country': 'Philippines',
        'state': 'Metro Manila',
        'city': 'Quezon City',
        'district': '',
      },
    );

    expect(response.data!['success'], isTrue);
  });

  test('ApiService enables onboarding mocks in development', () async {
    final storage = _MockStorageService();
    when(storage.readToken).thenAnswer((_) async => null);
    when(storage.readRefreshToken).thenAnswer((_) async => null);
    when(storage.clearSession).thenAnswer((_) async {});
    final api = ApiService(storage: storage);

    final login = await api.post(ApiEndpoints.login, {
      'email': 'admin@example.com',
      'password': 'Password123!',
    });
    final countries = await api.get(ApiEndpoints.locationCountries);

    expect((login as Map<String, dynamic>)['id'], '1');
    expect((countries as Map<String, dynamic>)['data'], isNotEmpty);
  });
}
