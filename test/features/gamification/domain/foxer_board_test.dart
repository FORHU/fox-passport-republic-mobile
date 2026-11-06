import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _entry(
  int position,
  String id, {
  String role = 'venueFoxer',
  double rating = 4.8,
  int reviews = 126,
}) =>
    {
      'position': position,
      'userId': id,
      'name': 'Foxer $id',
      'avatarUrl': null,
      'role': role,
      'city': 'Manila',
      'rankTitle': 'Veteran',
      'starRating': rating,
      'reviewCount': reviews,
      'completedBookings': 40,
    };

void main() {
  test('reads a board the way the API sends it', () {
    final board = FoxerBoard.fromJson(
      {
        'tab': 'top_rated',
        'role': 'venueFoxer',
        'city': 'Manila',
        'entries': [_entry(1, 'a'), _entry(2, 'b')],
        'userPosition': _entry(2, 'b'),
      },
      requestedRole: LeaderboardRole.venue,
    );

    expect(board.tab, FoxerTab.topRated);
    expect(board.role, LeaderboardRole.venue);
    expect(board.city, 'Manila');
    expect(board.rows.map((r) => r.position), [1, 2]);
    expect(board.rows.first.rankName, 'Veteran');
    expect(board.rows.first.starRating, 4.8);
    expect(board.rows.first.reviewCount, 126);
    expect(board.meIsListed, isTrue);
  });

  test('a caller further down than the rows is not listed', () {
    final board = FoxerBoard.fromJson(
      {
        'tab': 'most_booked',
        'entries': [_entry(1, 'a')],
        'userPosition': _entry(51, 'z'),
      },
      requestedRole: LeaderboardRole.gear,
    );

    expect(board.tab, FoxerTab.mostBooked);
    expect(board.me?.position, 51);
    expect(board.meIsListed, isFalse);
  });

  test('a board without the caller has no pinned place', () {
    final board = FoxerBoard.fromJson(
      const {
        'tab': 'rising',
        'entries': <Object>[],
        'userPosition': null,
      },
      requestedRole: LeaderboardRole.event,
    );

    expect(board.tab, FoxerTab.rising);
    expect(board.me, isNull);
    expect(board.rows, isEmpty);
  });

  test("a row that names no known role takes the board's role", () {
    final board = FoxerBoard.fromJson(
      {
        'entries': [_entry(1, 'a', role: 'Foxer')],
      },
      requestedRole: LeaderboardRole.services,
    );

    expect(board.role, LeaderboardRole.services);
    expect(board.rows.single.role, LeaderboardRole.services);
  });

  test('leaves out what is not a row and fills in what is missing', () {
    final board = FoxerBoard.fromJson(
      const {
        'entries': [
          'junk',
          {'userId': 'x'},
        ],
      },
      requestedRole: LeaderboardRole.venue,
    );

    expect(board.tab, FoxerTab.topRated);
    expect(board.rows, hasLength(1));
    expect(board.rows.single.name, '');
    expect(board.rows.single.rankName, '');
    expect(board.rows.single.reviewCount, 0);
  });

  test('a rating only counts from five reviews on', () {
    final few = FoxerBoard.fromJson(
      {
        'entries': [_entry(1, 'a', reviews: 4)],
      },
      requestedRole: LeaderboardRole.venue,
    ).rows.single;
    final enough = FoxerBoard.fromJson(
      {
        'entries': [_entry(1, 'a', reviews: 5)],
      },
      requestedRole: LeaderboardRole.venue,
    ).rows.single;

    expect(few.hasRating, isFalse);
    expect(enough.hasRating, isTrue);
  });

  test('roles and tabs map to and from their names', () {
    expect(LeaderboardRole.venue.accountRole, 'venueFoxer');
    expect(LeaderboardRole.performers.accountRole, 'performerFoxer');
    for (final role in LeaderboardRole.values) {
      expect(LeaderboardRole.fromRoute(role.name), role);
      expect(LeaderboardRole.fromAccountRole(role.accountRole), role);
    }
    expect(LeaderboardRole.fromRoute('venueFoxer'), isNull);
    expect(LeaderboardRole.fromAccountRole('venue'), isNull);
    expect(LeaderboardRole.fromAccountRole(null), isNull);

    expect(FoxerTab.topRated.api, 'top_rated');
    for (final tab in FoxerTab.values) {
      expect(FoxerTab.fromApi(tab.api), tab);
    }
    expect(FoxerTab.fromApi('best'), isNull);
  });
}
