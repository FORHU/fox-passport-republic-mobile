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

  void stub(String endpoint, Object? answer) => when(
        () => api.get(endpoint, query: any(named: 'query')),
      ).thenAnswer((_) async => answer);

  group('the Foxer board', () {
    Map<String, dynamic> board() => {
          'success': true,
          'data': {
            'tab': 'top_rated',
            'role': 'venueFoxer',
            'entries': <Object>[],
            'userPosition': null,
          },
        };

    test('asks for the role as an account role, and Top rated by default',
        () async {
      stub(ApiEndpoints.leaderboardFoxers, board());

      final result = await repository.foxers(LeaderboardRole.venue);

      expect(result.role, LeaderboardRole.venue);
      verify(
        () => api.get(
          ApiEndpoints.leaderboardFoxers,
          query: {'role': 'venueFoxer', 'tab': 'top_rated'},
        ),
      ).called(1);
    });

    test('sends the tab it was given', () async {
      stub(ApiEndpoints.leaderboardFoxers, board());

      await repository.foxers(
        LeaderboardRole.performers,
        tab: FoxerTab.rising,
      );

      verify(
        () => api.get(
          ApiEndpoints.leaderboardFoxers,
          query: {'role': 'performerFoxer', 'tab': 'rising'},
        ),
      ).called(1);
    });

    test('sends the city trimmed, and leaves it out when it is blank',
        () async {
      stub(ApiEndpoints.leaderboardFoxers, board());

      await repository.foxers(
        LeaderboardRole.gear,
        tab: FoxerTab.mostBooked,
        city: '  Davao ',
      );
      await repository.foxers(LeaderboardRole.gear, city: '   ');

      verify(
        () => api.get(
          ApiEndpoints.leaderboardFoxers,
          query: {
            'role': 'gearFoxer',
            'tab': 'most_booked',
            'city': 'Davao',
          },
        ),
      ).called(1);
      verify(
        () => api.get(
          ApiEndpoints.leaderboardFoxers,
          query: {'role': 'gearFoxer', 'tab': 'top_rated'},
        ),
      ).called(1);
    });

    test('a response with no data is an error, not an empty board', () async {
      stub(ApiEndpoints.leaderboardFoxers, {'success': true});

      expect(
        () => repository.foxers(LeaderboardRole.event),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
