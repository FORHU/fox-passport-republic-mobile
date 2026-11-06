import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(
  int position,
  String id, {
  bool isMe = false,
  int level = 5,
}) =>
    {
      'position': position,
      'userId': id,
      'name': 'Citizen $id',
      'username': 'c_$id',
      'image': null,
      'city': 'Manila',
      'level': level,
      'rank': {'number': 3, 'name': 'Explorer', 'rarity': 'Uncommon'},
      'isMe': isMe,
    };

void main() {
  test('reads a board the way the API sends it', () {
    final board = CitizenBoard.fromJson({
      'tab': 'month',
      'city': null,
      'month': '2026-11',
      'rows': [_row(1, 'a'), _row(1, 'b'), _row(3, 'c', isMe: true)],
      'me': _row(3, 'c', isMe: true),
    });

    expect(board.tab, CitizenTab.month);
    expect(board.month, '2026-11');
    expect(board.rows.map((r) => r.position), [1, 1, 3]);
    expect(board.rows.first.rankName, 'Explorer');
    expect(board.rows.first.level, 5);
    expect(board.meIsListed, isTrue);
  });

  test('all time has no month, and a caller further down is not listed', () {
    final board = CitizenBoard.fromJson({
      'tab': 'all',
      'month': null,
      'rows': [_row(1, 'a')],
      'me': _row(40, 'z', isMe: true),
    });

    expect(board.tab, CitizenTab.all);
    expect(board.month, isNull);
    expect(board.me?.position, 40);
    expect(board.meIsListed, isFalse);
  });

  test('a city board for a caller with no city has no city and no rows', () {
    final board = CitizenBoard.fromJson(const {
      'tab': 'city',
      'city': null,
      'month': '2026-11',
      'rows': <Object>[],
      'me': null,
    });

    expect(board.tab, CitizenTab.city);
    expect(board.city, isNull);
    expect(board.rows, isEmpty);
    expect(board.me, isNull);
  });

  test('leaves out what is not a row and fills in what is missing', () {
    final board = CitizenBoard.fromJson(const {
      'rows': [
        'junk',
        {'userId': 'x'},
      ],
    });

    expect(board.rows, hasLength(1));
    expect(board.rows.single.name, '');
    expect(board.rows.single.level, 1);
    expect(board.rows.single.isMe, isFalse);
    expect(board.tab, CitizenTab.month);
  });

  test('tabs and sides map to and from their names', () {
    for (final tab in CitizenTab.values) {
      expect(CitizenTab.fromApi(tab.api), tab);
    }
    for (final side in LeaderboardSide.values) {
      expect(LeaderboardSide.fromApi(side.api), side);
    }
    expect(CitizenTab.fromApi('week'), isNull);
    expect(LeaderboardSide.fromApi(null), isNull);
  });
}
