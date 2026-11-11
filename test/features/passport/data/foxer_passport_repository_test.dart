import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late PassportRepository repository;

  setUp(() {
    api = _MockApiService();
    repository = PassportRepository(api);
  });

  void stubMe(Map<String, dynamic> data) =>
      when(() => api.get(ApiEndpoints.passportMe)).thenAnswer(
        (_) async => {'success': true, 'data': data},
      );

  void stubBadges(List<Map<String, dynamic>> badges) =>
      when(() => api.get(ApiEndpoints.passportBadges)).thenAnswer(
        (_) async => {'success': true, 'data': badges},
      );

  test('reads the perks for the role it was asked for', () async {
    stubMe({
      'perks': ['venue_authority', 'city_badge'],
      'userBadges': <Object>[],
    });
    stubBadges(const []);

    final p = await repository.loadForPath('venueFoxer');

    expect(p.path, 'venueFoxer');
    expect(p.perks, ['venue_authority', 'city_badge']);
  });

  test('a Foxer with no perks yet has an empty list', () async {
    stubMe({'userBadges': <Object>[]});
    stubBadges(const []);

    final p = await repository.loadForPath('eventFoxer');

    expect(p.perks, isEmpty);
  });

  test('keeps badges for this role or for none, earned ones first', () async {
    stubMe({
      'userBadges': [
        {
          'badge': {'id': 'b1', 'name': 'Host Master', 'path': 'venueFoxer'},
        },
        {
          'badge': {'id': 'b2', 'name': 'Evangelist', 'path': 'eventFoxer'},
        },
      ],
    });
    stubBadges([
      {'id': 'b1', 'name': 'Host Master', 'path': 'venueFoxer'},
      {'id': 'b2', 'name': 'Evangelist', 'path': 'eventFoxer'},
      {'id': 'b3', 'name': 'City Builder', 'path': 'venueFoxer'},
      {'id': 'b4', 'name': 'Early Adopter', 'path': null},
    ]);

    final p = await repository.loadForPath('venueFoxer');

    expect(
      p.badges.map((b) => '${b.name}:${b.earned}'),
      ['Host Master:true', 'City Builder:false', 'Early Adopter:false'],
    );
  });

  test('a response with no data is an error, not an empty Passport', () async {
    when(() => api.get(ApiEndpoints.passportMe))
        .thenAnswer((_) async => {'success': true});

    expect(
      () => repository.loadForPath('venueFoxer'),
      throwsA(isA<FormatException>()),
    );
  });
}
