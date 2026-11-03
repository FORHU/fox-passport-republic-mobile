import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/team_detail_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/team_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _MockRepo extends Mock implements SpacesRepository {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ada',
          roleType: ['venueFoxer', 'eventFoxer'],
        ),
      );
}

const _venue = TeamTarget(isEvent: false, id: 'v1', name: 'Sky Hall');
const _event = TeamTarget(isEvent: true, id: 'e1', name: 'Launch Night');

Map<String, dynamic> _member(
  String id, {
  String kind = 'organizer',
  String state = 'active',
  String? name = 'Ada',
  String email = 'ada@x.co',
  String? endReason,
  String? expiresAt,
}) =>
    {
      'id': id,
      'userId': 'user-$id',
      'kind': kind,
      'state': state,
      'status': state,
      'expiresAt': expiresAt,
      'respondedAt': null,
      'endReason': endReason,
      'user': {'id': 'user-$id', 'name': name, 'email': email},
    };

TeamMember _parsed(Map<String, dynamic> row) => TeamMember.tryParse(row)!;

void main() {
  setUpAll(() {
    registerFallbackValue(_venue);
    registerFallbackValue(TeamKind.organizer);
  });

  group('the team models', () {
    test('a member reads its person and the way the API words it', () {
      final m = _parsed(_member('a', kind: 'check_in_helper'));

      expect(m.kind, TeamKind.checkInHelper);
      expect(m.userId, 'user-a');
      expect(m.title, 'Ada');
      expect(_parsed(_member('b', name: null)).title, 'ada@x.co');
    });

    test('rows it cannot read are skipped', () {
      expect(TeamMember.tryParse({'id': 'a'}), isNull);
      expect(TeamMember.tryParse(_member('a', kind: 'odd')), isNull);
      expect(TeamMember.tryParse('nope'), isNull);
    });

    test('the roster sorts a team the way the screen shows it', () {
      final roster = TeamRoster([
        _parsed(_member('a')),
        _parsed(_member('b', state: 'invited')),
        _parsed(_member('c', state: 'requested')),
        _parsed(_member('d', state: 'declined')),
        _parsed(_member('e', state: 'ended', endReason: 'removed')),
        _parsed(_member('f', state: 'expired')),
      ]);

      expect(roster.active.single.id, 'a');
      expect(roster.invited.single.id, 'b');
      expect(roster.requests.single.id, 'c');
      expect(roster.past.map((m) => m.id), ['d', 'e', 'f']);
      expect(roster.isEmpty, isFalse);
      // Anyone on the team, invited or asking, cannot be invited again.
      expect(roster.memberIds, {'user-a', 'user-b', 'user-c'});
      expect(TeamRoster(const []).isEmpty, isTrue);
    });

    test('an organizer card has no email and tolerates missing parts', () {
      final card = OrganizerCard.tryParse({
        'id': 'o1',
        'name': 'Bea',
        'city': 'Cebu',
        'specializations': ['beach_resort', 3],
        'level': 4,
      })!;

      expect(card.level, 4);
      expect(card.specializations, ['beach_resort']);
      expect(OrganizerCard.tryParse({'id': 'o2'})!.level, 1);
      expect(OrganizerCard.tryParse({'name': 'x'}), isNull);
    });

    test('only events that can still take a team are listed', () {
      expect(
        teamTargetFromEvent({'id': 'e', 'name': 'A', 'eventStatus': 'live'}),
        isNotNull,
      );
      expect(
        teamTargetFromEvent(
          {'id': 'e', 'name': 'A', 'eventStatus': 'cancelled'},
        ),
        isNull,
      );
      expect(
        teamTargetFromEvent(
          {'id': 'e', 'name': 'A', 'eventStatus': 'completed'},
        ),
        isNull,
      );
      expect(teamTargetFromEvent({'name': 'A'}), isNull);
    });
  });

  group('the team calls', () {
    late _MockApi api;
    late SpacesRepository repo;

    setUp(() {
      api = _MockApi();
      repo = SpacesRepository(api, 'u1');
      when(() => api.post(any(), any())).thenAnswer((_) async => {});
      when(() => api.post(any())).thenAnswer((_) async => {});
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      when(() => api.delete(any())).thenAnswer((_) async => {});
    });

    test('a venue and an event each have their own team route', () async {
      when(() => api.get(any())).thenAnswer((_) async => {'data': <Object>[]});

      await repo.team(_venue);
      await repo.team(_event);

      verify(() => api.get('/venues/v1/appointments')).called(1);
      verify(() => api.get('/events/e1/appointments')).called(1);
    });

    test('reads the team, skipping rows it cannot read', () async {
      when(() => api.get('/venues/v1/appointments')).thenAnswer(
        (_) async => {
          'data': [
            _member('a'),
            {'id': 'bad'},
          ],
        },
      );

      expect((await repo.team(_venue)).map((m) => m.id), ['a']);
    });

    test('invites by email, by picked person, and adds a helper', () async {
      await repo.appoint(_venue, TeamKind.organizer, email: ' a@b.co ');
      await repo.appoint(_venue, TeamKind.organizer, userId: 'o1');
      await repo.appoint(_event, TeamKind.checkInHelper, email: 'h@b.co');

      verify(
        () => api.post(
          '/venues/v1/appointments',
          {'kind': 'organizer', 'email': 'a@b.co'},
        ),
      ).called(1);
      verify(
        () => api.post(
          '/venues/v1/appointments',
          {'kind': 'organizer', 'userId': 'o1'},
        ),
      ).called(1);
      verify(
        () => api.post(
          '/events/e1/appointments',
          {'kind': 'check_in_helper', 'email': 'h@b.co'},
        ),
      ).called(1);
    });

    test('removing, answering and the requests switch', () async {
      await repo.removeFromTeam(_venue, 'a1');
      await repo.answerTeamRequest(_venue, 'a1', accept: true);
      await repo.answerTeamRequest(_event, 'a2', accept: false);
      await repo.setAcceptsOrganizerRequests(_venue, value: true);

      verify(() => api.delete('/venues/v1/appointments/a1')).called(1);
      verify(() => api.post('/venues/v1/appointments/a1/approve-request'))
          .called(1);
      verify(() => api.post('/events/e1/appointments/a2/decline-request'))
          .called(1);
      verify(
        () => api.patch(
          '/venues/v1/appointments/settings',
          {'acceptsOrganizerRequests': true},
        ),
      ).called(1);
    });

    test('reads whether requests are accepted', () async {
      when(() => api.get('/venues/v1/appointments/settings')).thenAnswer(
        (_) async => {
          'data': {'acceptsOrganizerRequests': true},
        },
      );

      expect(await repo.acceptsOrganizerRequests(_venue), isTrue);
    });

    test('searches Organizers by what was typed', () async {
      when(
        () => api.get(
          '/appointments/organizers',
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': [
            {
              'id': 'o1',
              'name': 'Bea',
              'level': 2,
              'specializations': <String>[],
            },
          ],
        },
      );

      final found = await repo.searchOrganizers(' bea ');

      expect(found.single.name, 'Bea');
      verify(
        () => api.get('/appointments/organizers', query: {'q': 'bea'}),
      ).called(1);
    });

    test('lists upcoming events page by page, without the finished', () async {
      when(
        () => api.get('/events', query: any(named: 'query')),
      ).thenAnswer(
        (_) async => {
          'events': [
            {'id': 'e1', 'name': 'A', 'eventStatus': 'live'},
            {'id': 'e2', 'name': 'B', 'eventStatus': 'completed'},
          ],
          'total': 2,
        },
      );

      final events = await repo.teamEvents();

      expect(events.map((e) => e.id), ['e1']);
      verify(
        () => api.get(
          '/events',
          query: {'organizerId': 'u1', 'limit': 50, 'page': 1},
        ),
      ).called(1);
    });
  });

  group('the Team screens', () {
    late _MockRepo repo;
    var members = <TeamMember>[];

    setUp(() {
      repo = _MockRepo();
      members = [];
      when(() => repo.team(any())).thenAnswer((_) async => members);
      when(() => repo.acceptsOrganizerRequests(any()))
          .thenAnswer((_) async => false);
      when(
        () => repo.setAcceptsOrganizerRequests(
          any(),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.removeFromTeam(any(), any())).thenAnswer((_) async {});
      when(
        () => repo.answerTeamRequest(
          any(),
          any(),
          accept: any(named: 'accept'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repo.appoint(
          any(),
          any(),
          email: any(named: 'email'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
      when(() => repo.searchOrganizers(any())).thenAnswer(
        (_) async => const [
          OrganizerCard(
            id: 'o1',
            name: 'Bea Cruz',
            level: 3,
            city: 'Cebu',
            specializations: ['beach_resort'],
          ),
          OrganizerCard(id: 'user-a', name: 'Ada', level: 1),
        ],
      );
    });

    Future<void> pump(WidgetTester tester, Widget home) async {
      // A phone, so a button too wide for a row would overflow here.
      tester.view
        ..physicalSize = const Size(390, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            spacesRepositoryProvider.overrideWithValue(repo),
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(_Session.new),
            teamVenuesProvider.overrideWith(
              (ref) async => [_venue],
            ),
            teamEventsProvider.overrideWith(
              (ref) async => [_event],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('the list shows venues for a Mayor, events for a Foxer', (
      tester,
    ) async {
      await pump(tester, const TeamPage(events: false));
      expect(find.text('Your venues'), findsOneWidget);
      expect(find.text('Sky Hall'), findsOneWidget);

      await pump(tester, const TeamPage(events: true));
      await tester.pumpAndSettle();
      expect(find.text('Your upcoming events'), findsOneWidget);
      expect(find.text('Launch Night'), findsOneWidget);
    });

    testWidgets('an empty team says only the owner runs it', (tester) async {
      await pump(tester, const TeamDetailPage(target: _venue));

      expect(find.text('No one else yet. Only you can run this.'), findsOne);
      expect(find.text('Send invitation'), findsOneWidget);
    });

    testWidgets('lists who is on the team and who is invited', (tester) async {
      members = [
        _parsed(_member('a')),
        _parsed(
          _member('b', state: 'invited', name: 'Ben', email: 'ben@x.co'),
        ),
        _parsed(_member('c', state: 'declined', name: 'Cy')),
      ];
      await pump(tester, const TeamDetailPage(target: _venue));

      expect(find.text('On the team'), findsOneWidget);
      expect(find.text('Waiting for an answer'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      // History stays folded away until asked for.
      expect(find.text('Cy'), findsNothing);
      await tester.tap(find.text('Past (1)'));
      await tester.pump();
      expect(find.text('Cy'), findsOneWidget);
      expect(find.textContaining('Declined'), findsWidgets);
    });

    testWidgets('invites an Organizer by email, then clears the box', (
      tester,
    ) async {
      await pump(tester, const TeamDetailPage(target: _venue));

      final send = find.widgetWithText(FilledButton, 'Send invitation');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'new@x.co');
      await tester.pump();
      await tester.tap(send);
      await tester.pump();

      verify(
        () => repo.appoint(_venue, TeamKind.organizer, email: 'new@x.co'),
      ).called(1);
      expect(find.text('Invitation sent'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('adds a Check-in Helper by email', (tester) async {
      await pump(tester, const TeamDetailPage(target: _event));

      await tester.tap(find.text('Check-in Helper').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'door@x.co');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add helper'));
      await tester.pump();

      verify(
        () => repo.appoint(_event, TeamKind.checkInHelper, email: 'door@x.co'),
      ).called(1);
    });

    testWidgets('finds Organizers by name and invites one', (tester) async {
      members = [_parsed(_member('a'))];
      await pump(tester, const TeamDetailPage(target: _venue));

      await tester.enterText(find.byType(TextField), 'be');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.textContaining('Bea Cruz'), findsOneWidget);
      expect(find.textContaining('Cebu'), findsOneWidget);
      // Someone already on the team cannot be invited again.
      final already = find.widgetWithText(FilledButton, 'On the team');
      expect(tester.widget<FilledButton>(already).onPressed, isNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Invite'));
      await tester.pump();

      verify(
        () => repo.appoint(_venue, TeamKind.organizer, userId: 'o1'),
      ).called(1);
    });

    testWidgets('removing asks first, and backing out does nothing', (
      tester,
    ) async {
      members = [_parsed(_member('a'))];
      await pump(tester, const TeamDetailPage(target: _venue));

      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      expect(find.text('Remove Ada?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.removeFromTeam(any(), any()));

      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pumpAndSettle();
      verify(() => repo.removeFromTeam(_venue, 'a')).called(1);
    });

    testWidgets('an invitation is withdrawn, not removed', (tester) async {
      members = [_parsed(_member('b', state: 'invited', name: 'Ben'))];
      await pump(tester, const TeamDetailPage(target: _venue));

      await tester.tap(find.byTooltip('Withdraw'));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw the invitation to Ben?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Withdraw'));
      await tester.pumpAndSettle();

      verify(() => repo.removeFromTeam(_venue, 'b')).called(1);
    });

    testWidgets('accepts and declines requests to join', (tester) async {
      members = [
        _parsed(_member('r1', state: 'requested', name: 'Rae')),
        _parsed(_member('r2', state: 'requested', name: 'Rob')),
      ];
      await pump(tester, const TeamDetailPage(target: _venue));

      expect(find.text('Requests to join'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Accept').first);
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Decline').last);
      await tester.pump();

      verify(
        () => repo.answerTeamRequest(_venue, 'r1', accept: true),
      ).called(1);
      verify(
        () => repo.answerTeamRequest(_venue, 'r2', accept: false),
      ).called(1);
    });

    testWidgets('the requests switch is saved', (tester) async {
      await pump(tester, const TeamDetailPage(target: _venue));

      await tester.tap(find.byType(Switch));
      await tester.pump();

      verify(
        () => repo.setAcceptsOrganizerRequests(_venue, value: true),
      ).called(1);
    });

    testWidgets("shows the server's words when it refuses", (tester) async {
      when(
        () => repo.appoint(
          any(),
          any(),
          email: any(named: 'email'),
          userId: any(named: 'userId'),
        ),
      ).thenThrow(const ServerException('No user found with that email'));
      await pump(tester, const TeamDetailPage(target: _venue));

      await tester.enterText(find.byType(TextField), 'who@x.co');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Send invitation'));
      await tester.pump();

      expect(find.text('No user found with that email'), findsOneWidget);
      // The box keeps what was typed so it can be fixed.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'who@x.co',
      );
    });

    testWidgets('a team that will not load can be retried', (tester) async {
      when(() => repo.team(any())).thenThrow(const NetworkException());
      await pump(tester, const TeamDetailPage(target: _venue));

      expect(find.text("Couldn't load your team."), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
