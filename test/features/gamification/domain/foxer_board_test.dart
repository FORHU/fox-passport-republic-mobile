import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row(
  int position,
  String id, {
  bool isMe = false,
  String role = 'venue',
}) =>
    {
      'position': position,
      'userId': id,
      'name': 'Foxer $id',
      'username': 'f_$id',
      'image': null,
      'city': 'Manila',
      'role': role,
      'rank': {'number': 4, 'name': 'Veteran', 'rarity': 'Uncommon'},
      'isMe': isMe,
    };

void main() {
  test('reads a board the way the API sends it', () {
    final board = FoxerBoard.fromJson({
      'tab': 'most_booked',
      'role': 'venue',
      'city': 'Manila',
      'month': '2026-11',
      'rows': [_row(1, 'a'), _row(1, 'b'), _row(3, 'c', isMe: true)],
      'me': _row(3, 'c', isMe: true),
    });

    expect(board.role, LeaderboardRole.venue);
    expect(board.city, 'Manila');
    expect(board.month, '2026-11');
    expect(board.rows.map((r) => r.position), [1, 1, 3]);
    expect(board.rows.first.rankName, 'Veteran');
    expect(board.rows.last.isMe, isTrue);
    expect(board.meIsListed, isTrue);
  });

  test('a caller further down than the rows is not listed', () {
    final board = FoxerBoard.fromJson({
      'role': 'event',
      'month': '2026-11',
      'rows': [_row(1, 'a', role: 'event')],
      'me': _row(27, 'z', isMe: true, role: 'event'),
    });

    expect(board.me?.position, 27);
    expect(board.meIsListed, isFalse);
  });

  test('a board without the caller has no pinned place', () {
    final board = FoxerBoard.fromJson(const {
      'role': 'gear',
      'month': '2026-11',
      'rows': <Object>[],
      'me': null,
    });

    expect(board.me, isNull);
    expect(board.meIsListed, isFalse);
    expect(board.rows, isEmpty);
  });

  test('leaves out what is not a row and fills in what is missing', () {
    final board = FoxerBoard.fromJson(const {
      'rows': [
        'junk',
        {'userId': 'x'},
      ],
    });

    expect(board.rows, hasLength(1));
    expect(board.rows.single.name, '');
    expect(board.rows.single.rankName, '');
    expect(board.rows.single.isMe, isFalse);
    expect(board.month, '');
  });

  test('roles map to and from the API names', () {
    for (final role in LeaderboardRole.values) {
      expect(LeaderboardRole.fromApi(role.api), role);
    }
    expect(LeaderboardRole.fromApi('wizard'), isNull);
    expect(LeaderboardRole.fromApi(null), isNull);
  });
}
