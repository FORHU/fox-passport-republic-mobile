import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

void main() {
  late _MockApi api;
  late LeaderboardRepository repository;

  setUp(() {
    api = _MockApi();
    repository = LeaderboardRepository(api);
  });

  Map<String, dynamic> board() => {
        'success': true,
        'data': {
          'role': 'venue',
          'month': '2026-11',
          'rows': <Object>[],
          'me': null,
        },
      };

  test('asks for the Most booked board of the role', () async {
    when(
      () => api.get(
        ApiEndpoints.leaderboardFoxers,
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => board());

    final result = await repository.foxers(LeaderboardRole.venue);

    expect(result.role, LeaderboardRole.venue);
    verify(
      () => api.get(
        ApiEndpoints.leaderboardFoxers,
        query: {'role': 'venue', 'tab': 'most_booked'},
      ),
    ).called(1);
  });

  test('sends the city trimmed, and leaves it out when it is blank', () async {
    when(
      () => api.get(
        ApiEndpoints.leaderboardFoxers,
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => board());

    await repository.foxers(LeaderboardRole.gear, city: '  Davao ');
    await repository.foxers(LeaderboardRole.gear, city: '   ');

    verify(
      () => api.get(
        ApiEndpoints.leaderboardFoxers,
        query: {'role': 'gear', 'tab': 'most_booked', 'city': 'Davao'},
      ),
    ).called(1);
    verify(
      () => api.get(
        ApiEndpoints.leaderboardFoxers,
        query: {'role': 'gear', 'tab': 'most_booked'},
      ),
    ).called(1);
  });

  test('a response with no data is an error, not an empty board', () async {
    when(
      () => api.get(
        ApiEndpoints.leaderboardFoxers,
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => {'success': true});

    expect(
      () => repository.foxers(LeaderboardRole.event),
      throwsA(isA<FormatException>()),
    );
  });
}
