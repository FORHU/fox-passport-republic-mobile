import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/features/perks/presentation/pages/my_perks_page.dart';
import 'package:flutter_template/features/perks/presentation/pages/perk_code_page.dart';
import 'package:flutter_template/features/perks/presentation/pages/perk_detail_page.dart';
import 'package:flutter_template/features/perks/presentation/widgets/perks_section.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _perk({
  String id = 'p1',
  String title = 'Free welcome drink',
  int cost = 500,
  int short = 0,
  String issuer = 'venue',
  int? remaining = 3,
}) =>
    {
      'id': id,
      'issuerType': issuer,
      'title': title,
      'description': 'One drink when you arrive.',
      'tokenCost': cost,
      'remaining': remaining,
      'validDays': 30,
      'tokensShort': short,
    };

Map<String, dynamic> _listing(List<Map<String, dynamic>> perks) => {
      'success': true,
      'data': {'balance': 1240, 'held': 120, 'perks': perks},
    };

Map<String, dynamic> _detail({
  List<Map<String, dynamic>> bookings = const [
    {'id': 'b1', 'name': 'Garden wedding', 'startAt': '2026-12-01T10:00:00Z'},
  ],
  int balance = 1240,
}) =>
    {
      'success': true,
      'data': {'balance': balance, 'perk': _perk(), 'bookings': bookings},
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
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => Scaffold(body: home)),
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
    test('a perk reads its price and how short the person is', () {
      final p = Perk.fromJson(_perk(cost: 1500, short: 260, issuer: 'host'));

      expect(p.tokenCost, 1500);
      expect(p.tokensShort, 260);
      expect(p.isHost, isTrue);
      expect(p.canAfford, isFalse);
    });

    test('a returned or past-date perk reads as expired, a used one as used',
        () {
      MyPerk of(Map<String, dynamic> j) => MyPerk.fromJson({
            'id': 'r',
            'title': 't',
            'tokensSpent': 500,
            ...j,
          });

      expect(of({'status': 'ready'}).state, MyPerkState.ready);
      expect(
        of({'status': 'ready', 'expired': true}).state,
        MyPerkState.expired,
      );
      expect(of({'status': 'returned'}).state, MyPerkState.expired);
      expect(of({'status': 'used'}).state, MyPerkState.used);
    });
  });

  group('the Perks section', () {
    testWidgets('lists perks, who offers them and how many are left',
        (tester) async {
      when(() => api.get(ApiEndpoints.perks)).thenAnswer(
        (_) async => _listing([
          _perk(),
          _perk(
            id: 'p2',
            title: 'Bring a +1',
            cost: 1500,
            short: 260,
            issuer: 'host',
            remaining: 1,
          ),
        ]),
      );
      when(() => api.get(ApiEndpoints.perksMine))
          .thenAnswer((_) async => {'success': true, 'data': <Object>[]});

      await show(tester, const SingleChildScrollView(child: PerksSection()));

      expect(find.text('Free welcome drink'), findsOneWidget);
      expect(find.text('Offered by venue'), findsOneWidget);
      expect(find.text('Offered by host'), findsOneWidget);
      expect(find.text('3 left'), findsOneWidget);
      // The unaffordable one shows how far off it is, not a View button.
      expect(find.text('260 Tokens to go'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.textContaining('120 Tokens held'), findsOneWidget);
    });

    testWidgets('says so when there are no perks', (tester) async {
      when(() => api.get(ApiEndpoints.perks))
          .thenAnswer((_) async => _listing([]));
      when(() => api.get(ApiEndpoints.perksMine))
          .thenAnswer((_) async => {'success': true, 'data': <Object>[]});

      await show(tester, const PerksSection());

      expect(find.textContaining('No perks yet'), findsOneWidget);
    });

    testWidgets('offers a retry when it cannot load', (tester) async {
      when(() => api.get(ApiEndpoints.perks))
          .thenThrow(const NetworkException());
      when(() => api.get(ApiEndpoints.perksMine))
          .thenThrow(const NetworkException());

      await show(tester, const PerksSection());

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows how many of my perks are ready and opens them',
        (tester) async {
      when(() => api.get(ApiEndpoints.perks))
          .thenAnswer((_) async => _listing([]));
      when(() => api.get(ApiEndpoints.perksMine)).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'id': 'r1',
              'title': 'Drink',
              'status': 'ready',
              'tokensSpent': 500,
            },
          ],
        },
      );

      await show(
        tester,
        const PerksSection(),
        extra: [
          GoRoute(
            path: RouteNames.perksMine,
            builder: (_, __) => const Text('my perks screen'),
          ),
        ],
      );
      expect(find.text('My perks · 1 ready'), findsOneWidget);

      await tester.tap(find.text('My perks · 1 ready'));
      await tester.pumpAndSettle();

      expect(find.text('my perks screen'), findsOneWidget);
    });
  });

  group('the perk page', () {
    testWidgets('shows the booking, the price and the balance', (tester) async {
      when(() => api.get(ApiEndpoints.perk('p1')))
          .thenAnswer((_) async => _detail());

      await show(tester, const PerkDetailPage(perkId: 'p1'));

      expect(find.text('Free welcome drink'), findsOneWidget);
      expect(find.text('Garden wedding'), findsOneWidget);
      expect(find.text('You have 1,240'), findsOneWidget);
      expect(find.text('Redeem'), findsOneWidget);
    });

    testWidgets('cannot redeem with no booking at the venue', (tester) async {
      when(() => api.get(ApiEndpoints.perk('p1')))
          .thenAnswer((_) async => _detail(bookings: const []));

      await show(tester, const PerkDetailPage(perkId: 'p1'));

      expect(
        find.textContaining('No booking this perk works for'),
        findsOneWidget,
      );
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Redeem'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('cannot redeem without enough Tokens', (tester) async {
      when(() => api.get(ApiEndpoints.perk('p1')))
          .thenAnswer((_) async => _detail(balance: 100));

      await show(tester, const PerkDetailPage(perkId: 'p1'));

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Redeem'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('confirms, spends the Tokens and opens the code',
        (tester) async {
      when(() => api.get(ApiEndpoints.perk('p1')))
          .thenAnswer((_) async => _detail());
      when(
        () => api.post(ApiEndpoints.perkRedeem('p1'), {'bookingId': 'b1'}),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'redemptionId': 'r1',
            'code': 'FP-AAAA-BBBB',
            'tokensSpent': 500,
            'remainingCoins': 740,
            'expiresAt': '2026-12-18T10:00:00Z',
          },
        },
      );

      await show(
        tester,
        const PerkDetailPage(perkId: 'p1'),
        extra: [
          GoRoute(
            path: '/perk-code/:id',
            builder: (_, s) => Text('code for ${s.pathParameters['id']}'),
          ),
        ],
      );
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();

      expect(find.text('Use 500 Tokens?'), findsOneWidget);
      expect(find.text('740 Tokens'), findsOneWidget);

      await tester.tap(find.text('Use 500 Tokens'));
      await tester.pumpAndSettle();

      verify(
        () => api.post(ApiEndpoints.perkRedeem('p1'), {'bookingId': 'b1'}),
      ).called(1);
      expect(find.text('code for r1'), findsOneWidget);
    });

    testWidgets('keeps the sheet open and says why when the server refuses',
        (tester) async {
      when(() => api.get(ApiEndpoints.perk('p1')))
          .thenAnswer((_) async => _detail());
      when(
        () => api.post(ApiEndpoints.perkRedeem('p1'), {'bookingId': 'b1'}),
      ).thenThrow(const ServerException('That perk is sold out.'));

      await show(tester, const PerkDetailPage(perkId: 'p1'));
      await tester.tap(find.text('Redeem'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use 500 Tokens'));
      await tester.pumpAndSettle();

      expect(find.text('That perk is sold out.'), findsOneWidget);
      expect(find.text('Use 500 Tokens?'), findsOneWidget);
    });
  });

  group('the code page', () {
    testWidgets('shows the typed code, a countdown and when it is valid until',
        (tester) async {
      when(() => api.get(ApiEndpoints.perkCode('r1'))).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'code': 'FP-AAAA-BBBB',
            'live': 'FP-AAAA-BBBB.1.abc',
            'refreshInSeconds': 24,
            'title': 'Free welcome drink',
            'expiresAt': '2026-12-18T10:00:00Z',
          },
        },
      );

      await show(tester, const PerkCodePage(redemptionId: 'r1'));

      expect(find.text('FP-AAAA-BBBB'), findsOneWidget);
      expect(find.text('New code in 0:24'), findsOneWidget);
      expect(find.text('Free welcome drink'), findsOneWidget);

      // Stop the countdown timer before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('says the perk can no longer be used when it is refused',
        (tester) async {
      when(() => api.get(ApiEndpoints.perkCode('r1')))
          .thenThrow(const ServerException('This perk can no longer be used.'));

      await show(tester, const PerkCodePage(redemptionId: 'r1'));

      expect(find.text('This perk can no longer be used.'), findsOneWidget);
    });
  });

  group('My perks', () {
    testWidgets('groups ready, used and expired, and returns the Tokens',
        (tester) async {
      when(() => api.get(ApiEndpoints.perksMine)).thenAnswer(
        (_) async => {
          'success': true,
          'data': [
            {
              'id': 'r1',
              'title': 'Free welcome drink',
              'status': 'ready',
              'tokensSpent': 500,
              'expiresAt': '2026-12-18T10:00:00Z',
            },
            {
              'id': 'r2',
              'title': 'Starter on the house',
              'status': 'used',
              'tokensSpent': 800,
              'usedAt': '2026-11-10T10:00:00Z',
            },
            {
              'id': 'r3',
              'title': 'Free reschedule',
              'status': 'returned',
              'tokensSpent': 400,
              'expiresAt': '2026-11-01T10:00:00Z',
            },
          ],
        },
      );

      await show(tester, const MyPerksPage());

      expect(find.text('READY TO USE'), findsOneWidget);
      expect(find.text('USED'), findsOneWidget);
      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('Show code'), findsOneWidget);
      expect(find.text('400 Tokens returned to your wallet'), findsOneWidget);
    });

    testWidgets('says so when there are none', (tester) async {
      when(() => api.get(ApiEndpoints.perksMine))
          .thenAnswer((_) async => {'success': true, 'data': <Object>[]});

      await show(tester, const MyPerksPage());

      expect(find.text('You have no perks yet.'), findsOneWidget);
    });
  });
}
