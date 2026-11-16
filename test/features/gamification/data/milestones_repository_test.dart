import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

void main() {
  late _MockApi api;
  late MilestonesRepository repository;

  setUp(() {
    api = _MockApi();
    repository = MilestonesRepository(api);
  });

  Future<Object?> call() => api.get(ApiEndpoints.milestonesMe);

  test('reads the milestones the server sends', () async {
    when(call).thenAnswer(
      (_) async => {
        'success': true,
        'data': {'milestones': <Object>[], 'challenges': <Object>[]},
      },
    );

    final result = await repository.mine();

    expect(result.milestones, isEmpty);
    expect(result.challenges, isEmpty);
  });

  test('a 404 means the server has no milestones yet: empty, not an error',
      () async {
    when(call).thenThrow(
      const ServerException('Endpoint not found', statusCode: 404),
    );

    final result = await repository.mine();

    expect(result.milestones, isEmpty);
    expect(result.challenges, isEmpty);
  });

  test('other server errors still reach the screen', () async {
    when(call).thenThrow(
      const ServerException('Unexpected server error', statusCode: 500),
    );

    expect(repository.mine(), throwsA(isA<ServerException>()));
  });

  test('a network failure still reaches the screen', () async {
    when(call).thenThrow(const NetworkException());

    expect(repository.mine(), throwsA(isA<NetworkException>()));
  });

  test('a sign-in failure still reaches the screen', () async {
    when(call).thenThrow(
      const UnauthorizedException('Unauthorized', statusCode: 401),
    );

    expect(repository.mine(), throwsA(isA<UnauthorizedException>()));
  });
}
