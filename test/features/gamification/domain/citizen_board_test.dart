import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _entry(int position, String id, {int level = 5}) => {
      'position': position,
      'userId': id,
      'name': 'Citizen $id',
      'avatarUrl': null,
      'level': level,
      'rankTitle': 'Explorer',
      'city': 'Manila',
    };

void main() {
  test('reads a board the way the API sends it', () {
    final board = CitizenBoard.fromJson({
      'tab': 'this_month',
      'season': '2026-11',
      'entries': [_entry(1, 'a'), _entry(2, 'b'), _entry(3, 'c')],
      'userPosition': _entry(3, 'c'),
    });

    expect(board.tab, CitizenTab.month);
    expect(board.season, '2026-11');
    expect(board.rows.map((r) => r.position), [1, 2, 3]);
    expect(board.rows.first.rankName, 'Explorer');
    expect(board.rows.first.level, 5);
    expect(board.meIsListed, isTrue);
  });

  test('a caller further down than the rows is not listed', () {
    final board = CitizenBoard.fromJson({
      'tab': 'all_time',
      'season': '2026-11',
      'entries': [_entry(1, 'a')],
      'userPosition': _entry(51, 'z'),
    });

    expect(board.tab, CitizenTab.all);
    expect(board.me?.position, 51);
    expect(board.meIsListed, isFalse);
  });

  test('a board without the caller has no pinned place', () {
    final board = CitizenBoard.fromJson(const {
      'tab': 'my_city',
      'entries': <Object>[],
      'userPosition': null,
    });

    expect(board.tab, CitizenTab.city);
    expect(board.rows, isEmpty);
    expect(board.me, isNull);
    expect(board.season, isNull);
  });

  test('leaves out what is not a row and fills in what is missing', () {
    final board = CitizenBoard.fromJson(const {
      'entries': [
        'junk',
        {'userId': 'x'},
      ],
    });

    expect(board.rows, hasLength(1));
    expect(board.rows.single.name, '');
    expect(board.rows.single.level, 1);
    expect(board.tab, CitizenTab.month);
  });

  test('tabs and sides map to and from their names', () {
    expect(CitizenTab.month.api, 'this_month');
    expect(CitizenTab.all.api, 'all_time');
    expect(CitizenTab.city.api, 'my_city');
    for (final tab in CitizenTab.values) {
      expect(CitizenTab.fromApi(tab.api), tab);
    }
    for (final side in LeaderboardSide.values) {
      expect(LeaderboardSide.fromApi(side.api), side);
    }
    expect(CitizenTab.fromApi('month'), isNull);
    expect(LeaderboardSide.fromApi(null), isNull);
  });
}
