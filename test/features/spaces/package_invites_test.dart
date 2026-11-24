import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/spaces/data/package_invites_repository.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_invites.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// mobile#491: a Provider sees package invites, joins one, or declines with
/// a reason ("Other" needs a note).

class _MockRepo extends Mock implements PackageInvitesRepository {}

final _rows = <Map<String, dynamic>>[
  {
    'id': 'line-1',
    'type': 'service',
    'matchRequestStatus': 'pending',
    'agreedPrice': '15000',
    'currency': 'PHP',
    'date': '2026-12-12T00:00:00.000Z',
    'description': 'Ceremony and reception',
    'item': {'id': 'svc-1', 'name': 'Wedding Photography'},
    'template': {
      'id': 'tpl-1',
      'name': 'Garden Wedding Package',
      'targetCity': 'Cebu City',
      'targetState': 'Cebu',
      'owner': {'id': 'ef-1', 'name': 'Ivan Dela Cruz'},
    },
  },
  {
    'id': 'line-2',
    'type': 'asset',
    'matchRequestStatus': 'accepted',
    'item': {'id': 'a-1', 'name': 'Portable Sound Bar'},
    'template': {'id': 'tpl-2', 'name': 'Fiesta Birthday Cebu'},
  },
  {
    'id': 'line-3',
    'type': 'venue',
    'matchRequestStatus': 'declined',
    'declineReason': 'too_far',
    'item': {'id': 'v-1', 'name': 'Garden Hall'},
    'template': {'id': 'tpl-3', 'name': 'Corporate Gala'},
  },
];

List<PackageInvite> get _invites => [
      for (final r in _rows) PackageInvite.tryParse(r)!,
    ];

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(_invites.first));

  setUp(() {
    repo = _MockRepo();
    when(() => repo.list()).thenAnswer((_) async => _invites);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [packageInvitesRepositoryProvider.overrideWithValue(repo)],
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

  group('PackageInvite.tryParse', () {
    test('reads an incoming row, price given as a decimal string', () {
      final invite = _invites.first;
      expect(invite.status, InviteStatus.pending);
      expect(invite.packageName, 'Garden Wedding Package');
      expect(invite.itemName, 'Wedding Photography');
      expect(invite.hostName, 'Ivan Dela Cruz');
      expect(invite.city, 'Cebu City, Cebu');
      expect(invite.price, 15000);
      expect(invite.date, isNotNull);
    });

    test('reads the decline reason, and skips rows that are not invites', () {
      expect(_invites.last.declineReason, InviteDeclineReason.tooFar);
      expect(PackageInvite.tryParse({'id': 'x'}), isNull);
      expect(PackageInvite.tryParse('nope'), isNull);
    });
  });

  group('LineInvite.fromLine', () {
    test('reads a matched line, with the reason and note when declined', () {
      final line = LineInvite.fromLine({
        'matched': true,
        'matchRequestStatus': 'declined',
        'declineReason': 'other',
        'declineNote': '  Booked that weekend ',
      });
      expect(line?.status, InviteStatus.declined);
      expect(line?.reason, InviteDeclineReason.other);
      expect(line?.note, 'Booked that weekend');
      expect(
        LineInvite.fromLine({'matched': true, 'matchRequestStatus': 'secured'})
            ?.status,
        InviteStatus.accepted,
      );
    });

    test('a line that is not matched is not an invite', () {
      expect(
        LineInvite.fromLine(
          {'matched': false, 'matchRequestStatus': 'pending'},
        ),
        isNull,
      );
      expect(LineInvite.fromLine(null), isNull);
    });
  });

  testWidgets('a space lists only its own invites, pending then joined', (
    tester,
  ) async {
    await pump(
      tester,
      const Scaffold(body: PackageInvitesView(kind: RequestKind.service)),
    );
    expect(find.text('Garden Wedding Package'), findsOneWidget);
    expect(find.text('Review invite'), findsOneWidget);
    expect(find.text('Fiesta Birthday Cebu'), findsNothing, reason: 'gear');

    await pump(
      tester,
      const Scaffold(body: PackageInvitesView(kind: RequestKind.asset)),
    );
    expect(find.text("PACKAGES YOU'RE IN"), findsOneWidget);
    expect(find.text('Fiesta Birthday Cebu'), findsOneWidget);
    expect(
      find.text('Garden Wedding Package'),
      findsNothing,
      reason: 'service',
    );
  });

  testWidgets('says so when the space has no invites', (tester) async {
    // The only venue invite was declined, so the Venue space has none.
    await pump(
      tester,
      const Scaffold(body: PackageInvitesView(kind: RequestKind.venue)),
    );

    expect(
      find.textContaining('No package invites for your venues yet'),
      findsOneWidget,
    );
    expect(find.text('Corporate Gala'), findsNothing);
  });

  testWidgets('the invite screen joins the package', (tester) async {
    when(
      () => repo.respond(
        any(),
        accept: any(named: 'accept'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    await pump(tester, PackageInvitePage(invite: _invites.first));

    expect(
      find.text(
        'Ivan Dela Cruz wants your Wedding Photography in Garden Wedding '
        'Package',
      ),
      findsOneWidget,
    );
    expect(find.text('Ceremony and reception'), findsOneWidget);

    await tester.tap(find.text('Join package'));
    await tester.pumpAndSettle();

    verify(
      () => repo.respond(
        any(that: predicate<PackageInvite>((i) => i.id == 'line-1')),
        accept: true,
      ),
    ).called(1);
  });

  testWidgets('declining needs a reason, and Other needs a note', (
    tester,
  ) async {
    when(
      () => repo.respond(
        any(),
        accept: any(named: 'accept'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
    await pump(tester, PackageInvitePage(invite: _invites.first));

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Why not join this package?'), findsOneWidget);

    ElevatedButton send() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Decline request'),
        );
    expect(send().onPressed, isNull, reason: 'no reason picked');

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    expect(send().onPressed, isNull, reason: 'Other needs a note');
    expect(find.text('Add a note for Other.'), findsOneWidget);

    await tester.tap(find.text('Not available on that day'));
    await tester.pumpAndSettle();
    expect(send().onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const Key('invite-decline-note')),
      'Booked at another wedding',
    );
    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    verify(
      () => repo.respond(
        any(),
        accept: false,
        reason: InviteDeclineReason.unavailableOnDate,
        note: 'Booked at another wedding',
      ),
    ).called(1);
    expect(find.text('Why not join this package?'), findsNothing);
  });

  testWidgets('a refused answer shows what the API said', (tester) async {
    when(
      () => repo.respond(
        any(),
        accept: any(named: 'accept'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenThrow(const ServerException("You've already answered this invite"));
    await pump(tester, PackageInvitePage(invite: _invites.first));

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price too low'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    expect(find.text("You've already answered this invite"), findsOneWidget);
    expect(find.text('Why not join this package?'), findsOneWidget);
  });
}
