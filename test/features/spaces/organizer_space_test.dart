import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/domain/appointment_models.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/organizer_invitations_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/organizer_overview_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpacesRepository {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Sam',
          roleType: ['organizer'],
        ),
      );
}

Map<String, Object?> _row(
  String id, {
  String state = 'active',
  String kind = 'organizer',
  String name = 'Garden Wedding',
  String? startAt,
}) =>
    {
      'id': id,
      'kind': kind,
      'state': state,
      'appointedBy': {'id': 'm1', 'name': 'Maya', 'email': 'm@x.co'},
      'event': {
        'id': 'e$id',
        'name': name,
        'startAt': startAt ?? '2099-01-01T10:00:00Z',
        'endAt': '2099-01-01T18:00:00Z',
        'eventStatus': 'published',
      },
      'venue': null,
    };

void main() {
  group('MyAppointment', () {
    test('reads an event team row', () {
      final a = MyAppointment.tryParse(_row('1', state: 'invited'))!;

      expect(a.id, '1');
      expect(a.kind, TeamKind.organizer);
      expect(a.state, AppointmentState.invited);
      expect(a.name, 'Garden Wedding');
      expect(a.isEvent, isTrue);
      expect(a.appointedBy, 'Maya');
      expect(a.startAt, isNotNull);
    });

    test('reads a venue row and falls back to the venue name', () {
      final a = MyAppointment.tryParse({
        'id': '2',
        'kind': 'check_in_helper',
        'state': 'active',
        'event': null,
        'venue': {'id': 'v1', 'name': 'Sky Hall', 'city': 'Baguio'},
      })!;

      expect(a.name, 'Sky Hall');
      expect(a.place, 'Baguio');
      expect(a.isEvent, isFalse);
      expect(a.isOrganizer, isFalse);
    });

    test('skips a row with no id or an unknown kind, and reads new states', () {
      expect(MyAppointment.tryParse({'kind': 'organizer'}), isNull);
      expect(MyAppointment.tryParse({'id': '3', 'kind': 'boss'}), isNull);
      expect(
        MyAppointment.tryParse({'id': '4', 'kind': 'organizer', 'state': 'x'})
            ?.state,
        AppointmentState.other,
      );
    });
  });

  group('the Organizer space', () {
    test('opens for the organizer role only', () {
      expect(AppSpace.organizer.isAvailableTo(['organizer']), isTrue);
      expect(AppSpace.organizer.isAvailableTo(['eventFoxer']), isFalse);
      expect(AppSpace.forPath('/space/organizer/more'), AppSpace.organizer);
    });
  });

  group('pages', () {
    late _MockRepo repo;
    var rows = <Map<String, Object?>>[];

    setUp(() {
      repo = _MockRepo();
      rows = [];
      when(() => repo.myAppointments()).thenAnswer(
        (_) async => [
          for (final r in rows)
            if (MyAppointment.tryParse(r) case final a?) a,
        ],
      );
      when(
        () => repo.answerAppointment(any(), accept: any(named: 'accept')),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view
        ..physicalSize = const Size(390, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            authControllerProvider.overrideWith(_Session.new),
            spacesRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the Overview shows the buttons and says all is clear', (
      tester,
    ) async {
      await pump(tester, const OrganizerOverviewPage());

      expect(find.textContaining(', Sam'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Invitations'), findsOneWidget);
      expect(find.text("You're all caught up."), findsOneWidget);
      expect(find.text('Nothing coming up yet.'), findsOneWidget);
      expect(find.textContaining('accept an invitation'), findsOneWidget);
    });

    testWidgets('lists an invitation and accepts it', (tester) async {
      rows = [_row('1', state: 'invited', name: 'Sky Hall team')];
      await pump(tester, const OrganizerOverviewPage());

      expect(find.text('Sky Hall team'), findsOneWidget);
      expect(find.text('Organizer · Invited by Maya'), findsOneWidget);
      expect(find.text("You're all caught up."), findsNothing);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      verify(() => repo.answerAppointment('1', accept: true)).called(1);
    });

    testWidgets('declines an invitation', (tester) async {
      rows = [_row('1', state: 'invited')];
      await pump(tester, const OrganizerOverviewPage());

      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      verify(() => repo.answerAppointment('1', accept: false)).called(1);
    });

    testWidgets('shows the next event and the teams, two cards at most', (
      tester,
    ) async {
      rows = [
        _row('1', startAt: '2099-02-01T10:00:00Z'),
        _row('2', name: 'Corporate Mixer', startAt: '2099-01-10T10:00:00Z'),
        _row('3', name: 'Birthday Dinner', kind: 'check_in_helper'),
      ];
      await pump(tester, const OrganizerOverviewPage());
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();

      // The nearest start leads Next up.
      expect(find.text('You organize'), findsOneWidget);
      expect(find.text('Corporate Mixer'), findsWidgets);
      expect(find.text('ORGANIZING'), findsOneWidget);
      expect(find.text('Birthday Dinner'), findsNothing);
    });

    testWidgets('the Invitations page lists only invitations', (tester) async {
      rows = [
        _row('1', state: 'invited', name: 'Sky Hall team'),
        _row('2'),
      ];
      await pump(tester, const OrganizerInvitationsPage());

      expect(find.text('Sky Hall team'), findsOneWidget);
      expect(find.text('Garden Wedding'), findsNothing);
    });

    testWidgets('the Invitations page says when there are none', (
      tester,
    ) async {
      await pump(tester, const OrganizerInvitationsPage());

      expect(find.text('No invitations right now.'), findsOneWidget);
    });

    testWidgets('the Overview offers a retry when it will not load', (
      tester,
    ) async {
      when(() => repo.myAppointments()).thenThrow(Exception('offline'));
      await pump(tester, const OrganizerOverviewPage());

      expect(find.text("We couldn't load this right now."), findsOneWidget);
    });
  });
}
