import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/features/perks/presentation/pages/add_perk_page.dart';
import 'package:flutter_template/features/perks/presentation/pages/offered_perks_page.dart';
import 'package:flutter_template/features/perks/presentation/pages/package_perks_page.dart';
import 'package:flutter_template/features/perks/presentation/pages/perk_scan_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _offered({
  String id = 'p1',
  String title = 'Free welcome drink',
  bool active = true,
  int redeemed = 4,
  int remaining = 6,
}) =>
    {
      'id': id,
      'issuerType': 'host',
      'title': title,
      'tokenCost': 500,
      'remaining': remaining,
      'quantity': 10,
      'redeemed': redeemed,
      'active': active,
      'validDays': 30,
      'tokensShort': 0,
    };

Map<String, dynamic> _check(
  String result, {
  String? usedAt,
}) =>
    {
      'success': true,
      'data': {
        'result': result,
        'redemptionId': 'r1',
        'perk': {'title': 'Free welcome drink'},
        'guestFirstName': 'Maria',
        'booking': {
          'name': 'Garden wedding',
          'startAt': '2026-12-01T10:00:00Z',
        },
        'validUntil': '2026-12-18T10:00:00Z',
        'usedAt': usedAt,
        'venueName': 'Sky Hall',
      },
    };

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    List<GoRoute> extra = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(900, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        ...extra,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('me'),
          perksRepositoryProvider.overrideWithValue(PerksRepository(api)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('parsing', () {
    test('a check reads the guest, the booking and the state', () {
      final c = PerkCheck.fromJson(
        _check('used', usedAt: '2026-11-18T09:00:00Z')['data']!
            as Map<String, dynamic>,
      );

      expect(c.state, PerkCheckState.used);
      expect(c.guestFirstName, 'Maria');
      expect(c.bookingName, 'Garden wedding');
      expect(c.venueName, 'Sky Hall');
      expect(c.usedAt, isNotNull);
    });

    test('an offered perk reads how many were bought and its state', () {
      final o = OfferedPerk.fromJson(_offered(active: false));

      expect(o.redeemed, 4);
      expect(o.active, isFalse);
      expect(o.perk.remaining, 6);
    });
  });

  group('the offered perks page', () {
    testWidgets('lists my perks with how many were bought and are left',
        (tester) async {
      when(() => api.get(ApiEndpoints.perksOffered)).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            _offered(),
            _offered(id: 'p2', title: 'Starter', active: false),
          ],
        },
      );

      await show(tester, const OfferedPerksPage());

      expect(find.text('Free welcome drink'), findsOneWidget);
      expect(find.text('4 bought · 6 left'), findsOneWidget);
      expect(find.textContaining('Taken down'), findsOneWidget);
      // Only the live one can be taken down.
      expect(find.text('Take down'), findsOneWidget);
    });

    testWidgets('takes a perk down after a confirmation', (tester) async {
      when(() => api.get(ApiEndpoints.perksOffered)).thenAnswer(
        (_) async => {
          'success': true,
          'data': [_offered()],
        },
      );
      when(() => api.post(ApiEndpoints.perkTakeDown('p1'), any())).thenAnswer(
        (_) async => {
          'success': true,
          'data': {'returned': 2, 'tokens': 1000},
        },
      );

      await show(tester, const OfferedPerksPage());
      await tester.tap(find.text('Take down'));
      await tester.pumpAndSettle();
      expect(find.text('Take this perk down?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Take down'));
      await tester.pumpAndSettle();

      verify(() => api.post(ApiEndpoints.perkTakeDown('p1'), any())).called(1);
    });

    testWidgets('says so when there are none', (tester) async {
      when(() => api.get(ApiEndpoints.perksOffered))
          .thenAnswer((_) async => {'success': true, 'data': <Object>[]});

      await show(tester, const OfferedPerksPage());

      expect(find.text('You are not offering any perks yet.'), findsOneWidget);
    });
  });

  group('the add a perk page', () {
    const package =
        PerkTarget(id: 't1', name: 'Garden wedding', isVenue: false);
    const venue = PerkTarget(id: 'v1', name: 'Sky Hall', isVenue: true);

    testWidgets('shows the Token price from the peso value as it is typed',
        (tester) async {
      await show(
        tester,
        const AddPerkPage(targets: AsyncData([package])),
      );

      await tester.enterText(find.byType(TextFormField).at(2), '100');
      await tester.pump();

      expect(find.text('500 Tokens'), findsOneWidget);
    });

    testWidgets('sends an event package perk with its templateId',
        (tester) async {
      when(
        () => api.post(ApiEndpoints.perks, any()),
      ).thenAnswer(
        (_) async => {'success': true, 'data': _offered()},
      );
      await show(
        tester,
        const AddPerkPage(targets: AsyncData([package])),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Free drink');
      await tester.enterText(find.byType(TextFormField).at(2), '100');
      await tester.enterText(find.byType(TextFormField).at(3), '10');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Add perk'));
      await tester.pumpAndSettle();

      final body = verify(
        () => api.post(ApiEndpoints.perks, captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(body['templateId'], 't1');
      expect(body.containsKey('venueId'), isFalse);
      expect(body['title'], 'Free drink');
      expect(body['worthPhp'], 100);
      expect(body['quantity'], 10);
    });

    testWidgets('sends a venue perk with its venueId', (tester) async {
      when(
        () => api.post(ApiEndpoints.perks, any()),
      ).thenAnswer(
        (_) async => {'success': true, 'data': _offered()},
      );
      await show(tester, const AddPerkPage(targets: AsyncData([venue])));

      await tester.enterText(find.byType(TextFormField).at(0), 'Starter');
      await tester.enterText(find.byType(TextFormField).at(2), '160');
      await tester.enterText(find.byType(TextFormField).at(3), '5');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Add perk'));
      await tester.pumpAndSettle();

      final body = verify(
        () => api.post(ApiEndpoints.perks, captureAny()),
      ).captured.single as Map<String, dynamic>;
      expect(body['venueId'], 'v1');
      expect(body.containsKey('templateId'), isFalse);
    });

    testWidgets('does not send an empty form', (tester) async {
      await show(
        tester,
        const AddPerkPage(targets: AsyncData([package])),
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'Add perk'));
      await tester.pumpAndSettle();

      verifyNever(() => api.post(ApiEndpoints.perks, any()));
      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('says so when there is nowhere to add a perk', (tester) async {
      await show(tester, const AddPerkPage(targets: AsyncData([])));

      expect(
        find.textContaining('no event packages or venues'),
        findsOneWidget,
      );
    });
  });

  group('the scan page', () {
    Future<void> open(WidgetTester tester, {String? scanned}) => show(
          tester,
          PerkScanPage(scan: (_) async => scanned),
        );

    testWidgets('checks a typed code and shows a valid perk', (tester) async {
      when(() => api.post(ApiEndpoints.perksCheck, {'code': 'FP-AAAA-BBBB'}))
          .thenAnswer((_) async => _check('valid'));

      await open(tester);
      await tester.enterText(find.byType(TextFormField), 'FP-AAAA-BBBB');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Valid perk'), findsOneWidget);
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Mark as used'), findsOneWidget);
    });

    testWidgets('a scanned live code is sent as a live code', (tester) async {
      when(
        () => api.post(
          ApiEndpoints.perksCheck,
          {'live': 'FP-AAAA-BBBB.12.abc'},
        ),
      ).thenAnswer((_) async => _check('valid'));

      await open(tester, scanned: 'FP-AAAA-BBBB.12.abc');
      await tester.tap(find.text('Scan with the camera'));
      await tester.pumpAndSettle();

      expect(find.text('Valid perk'), findsOneWidget);
    });

    testWidgets('marks a valid perk used, once', (tester) async {
      when(() => api.post(ApiEndpoints.perksCheck, any()))
          .thenAnswer((_) async => _check('valid'));
      when(() => api.post(ApiEndpoints.perkUse('r1'), any())).thenAnswer(
        (_) async => {
          'success': true,
          'data': {'redemptionId': 'r1'},
        },
      );

      await open(tester);
      await tester.enterText(find.byType(TextFormField), 'FP-AAAA-BBBB');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as used'));
      await tester.pumpAndSettle();

      verify(() => api.post(ApiEndpoints.perkUse('r1'), any())).called(1);
      // The button is gone: it cannot be marked twice from here.
      expect(find.text('Mark as used'), findsNothing);
      expect(find.text('Scan another'), findsOneWidget);
    });

    testWidgets('an already used perk says so, with when and where',
        (tester) async {
      when(() => api.post(ApiEndpoints.perksCheck, any())).thenAnswer(
        (_) async => _check('used', usedAt: '2026-11-18T09:00:00Z'),
      );

      await open(tester);
      await tester.enterText(find.byType(TextFormField), 'FP-AAAA-BBBB');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Already used'), findsOneWidget);
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Mark as used'), findsNothing);
    });

    testWidgets('an expired perk cannot be marked used', (tester) async {
      when(() => api.post(ApiEndpoints.perksCheck, any()))
          .thenAnswer((_) async => _check('expired'));

      await open(tester);
      await tester.enterText(find.byType(TextFormField), 'FP-AAAA-BBBB');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Expired'), findsOneWidget);
      expect(find.text('Mark as used'), findsNothing);
    });

    testWidgets("shows the server's reason when a code is refused",
        (tester) async {
      when(() => api.post(ApiEndpoints.perksCheck, any())).thenThrow(
        const ServerException(
          'That code has expired. Ask the guest to refresh it.',
        ),
      );

      await open(tester);
      await tester.enterText(find.byType(TextFormField), 'FP-AAAA-BBBB');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(
        find.text('That code has expired. Ask the guest to refresh it.'),
        findsOneWidget,
      );
      expect(find.text('Valid perk'), findsNothing);
    });

    testWidgets('Scan another goes back to the start', (tester) async {
      when(() => api.post(ApiEndpoints.perksCheck, any()))
          .thenAnswer((_) async => _check('expired'));

      await open(tester);
      await tester.enterText(find.byType(TextFormField), 'FP-AAAA-BBBB');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan another'));
      await tester.pumpAndSettle();

      expect(find.text('Scan with the camera'), findsOneWidget);
    });
  });

  group('the perks of an event package', () {
    testWidgets('lists them and asks for the package', (tester) async {
      when(
        () => api.get(
          ApiEndpoints.perks,
          query: {'templateId': 't1'},
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'balance': 1240,
            'held': 0,
            'perks': [_offered()],
          },
        },
      );

      await show(tester, const PackagePerksPage(templateId: 't1'));

      expect(find.text('Perks for this event'), findsOneWidget);
      expect(find.text('Free welcome drink'), findsOneWidget);
    });

    testWidgets('says so when the host offers none', (tester) async {
      when(
        () => api.get(ApiEndpoints.perks, query: {'templateId': 't1'}),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {'balance': 0, 'held': 0, 'perks': <Object>[]},
        },
      );

      await show(tester, const PackagePerksPage(templateId: 't1'));

      expect(find.text('No perks for this event yet.'), findsOneWidget);
    });
  });

  test('the routes are where the rows point', () {
    expect(RouteNames.perksOffered, '/perks/offered');
    expect(RouteNames.perkNew, '/perks/new');
    expect(RouteNames.perkScan, '/perks/scan');
    expect(RouteNames.packagePerks('a b'), '/perks/package/a%20b');
  });
}
