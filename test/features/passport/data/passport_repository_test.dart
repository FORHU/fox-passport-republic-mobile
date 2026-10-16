import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late PassportRepository repository;

  setUp(() {
    AppConfig.instance = const AppConfig.dev();
    api = _MockApiService();
    repository = PassportRepository(api);
  });

  test('parses the Passport API response and badge catalogue', () async {
    when(() => api.get(ApiEndpoints.passportMe)).thenAnswer(
      (_) async => {
        'success': true,
        'data': {
          'paths': [
            {'totalXP': 1200},
          ],
          'stamps': [
            {
              'location': 'Manila, Philippines',
              'eventDate': '2025-01-02T03:04:05.000Z',
            },
          ],
          'userBadges': [
            {
              'badge': {'id': 'badge-1', 'name': 'First event'},
            },
          ],
        },
      },
    );
    when(() => api.get(ApiEndpoints.passportBadges)).thenAnswer(
      (_) async => {
        'success': true,
        'data': [
          {'id': 'badge-1', 'name': 'First event'},
          {'id': 'badge-2', 'name': 'Citizen'},
        ],
      },
    );

    final passport = await repository.load();

    expect(passport.totalXp, 1200);
    expect(passport.level, 2);
    expect(passport.stamps.single.label, 'MAN');
    expect(passport.badges.map((badge) => badge.earned), [true, false]);
    expect(passport.isSample, isFalse);
  });

  test('returns a genuine empty Passport for a new citizen', () async {
    when(() => api.get(ApiEndpoints.passportMe)).thenAnswer(
      (_) async => {
        'success': true,
        'data': {
          'paths': <Object>[],
          'stamps': <Object>[],
          'userBadges': <Object>[],
        },
      },
    );
    when(() => api.get(ApiEndpoints.passportBadges)).thenAnswer(
      (_) async => {'success': true, 'data': <Object>[]},
    );

    final passport = await repository.load();

    expect(passport.totalXp, 0);
    expect(passport.stamps, isEmpty);
    expect(passport.isSample, isFalse);
  });

  test('surfaces Passport API failures instead of returning demo data',
      () async {
    const failure = NetworkException();
    when(() => api.get(ApiEndpoints.passportMe)).thenThrow(failure);

    await expectLater(repository.load(), throwsA(same(failure)));
  });
}
