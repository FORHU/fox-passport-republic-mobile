import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/passport_more_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Session extends AuthController {
  _Session(this.roles);

  final List<String> roles;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'u1@example.com',
          name: 'Ada',
          roleType: roles,
        ),
      );
}

void main() {
  group('the rank line', () {
    const wallet = WalletSummary(
      coins: 410,
      pendingCoins: 0,
      totalEarnedCoins: 410,
      level: 3,
      rank: 'Regular',
      history: [],
    );

    Future<void> pumpRow(
      WidgetTester tester, {
      WalletSummary? summary,
      bool compact = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _Session(const ['venueFoxer'])),
            walletForPathProvider.overrideWith((ref, path) async {
              if (summary == null) throw Exception('no wallet');
              return summary;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PassportMoreRow(space: AppSpace.venue, compact: compact),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the badge, rank and level under Passport',
        (tester) async {
      await pumpRow(tester, summary: wallet);

      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('Regular · Level 3'), findsOneWidget);
      expect(find.byType(RankBadge), findsOneWidget);
    });

    testWidgets('shows nothing extra until the server has answered',
        (tester) async {
      await pumpRow(tester);

      expect(find.text('Passport'), findsOneWidget);
      expect(find.textContaining('Level'), findsNothing);
    });

    testWidgets('leaves the line out of the compact tile', (tester) async {
      await pumpRow(tester, summary: wallet, compact: true);

      expect(find.textContaining('Level'), findsNothing);
    });
  });

  Future<String?> tapRow(
    WidgetTester tester, {
    required AppSpace space,
    required List<String> roles,
  }) async {
    String? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: PassportMoreRow(space: space),
          ),
        ),
        GoRoute(
          path: RouteNames.foxerPassport,
          builder: (context, state) {
            opened = state.uri.queryParameters['path'];
            return const Scaffold(body: Text('opened'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => _Session(roles)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passport'));
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('a Venue space opens the venue path', (tester) async {
    expect(
      await tapRow(
        tester,
        space: AppSpace.venue,
        roles: const ['venueFoxer'],
      ),
      'venueFoxer',
    );
  });

  testWidgets('an Event space opens the event path', (tester) async {
    expect(
      await tapRow(
        tester,
        space: AppSpace.event,
        roles: const ['eventFoxer', 'venueFoxer'],
      ),
      'eventFoxer',
    );
  });

  testWidgets('a Performer in the Services space opens the performer path', (
    tester,
  ) async {
    expect(
      await tapRow(
        tester,
        space: AppSpace.services,
        roles: const ['providerFoxer'],
      ),
      'providerFoxer',
    );
  });

  testWidgets('an Organizer opens the organizer path', (tester) async {
    expect(
      await tapRow(
        tester,
        space: AppSpace.organizer,
        roles: const ['organizer'],
      ),
      'organizer',
    );
  });
}
