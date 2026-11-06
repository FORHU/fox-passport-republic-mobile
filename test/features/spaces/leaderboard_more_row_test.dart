import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/leaderboard_more_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
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
  group('the role a space opens the board on', () {
    test("is the space's own role", () {
      expect(
        LeaderboardMoreRow.roleFor(AppSpace.venue, const ['venueFoxer']),
        'venue',
      );
      expect(
        LeaderboardMoreRow.roleFor(AppSpace.event, const ['eventFoxer']),
        'event',
      );
      expect(
        LeaderboardMoreRow.roleFor(AppSpace.gear, const ['gearFoxer']),
        'gear',
      );
      expect(
        LeaderboardMoreRow.roleFor(AppSpace.services, const ['serviceFoxer']),
        'services',
      );
    });

    test('is performers for a Performer who only works the Services space', () {
      expect(
        LeaderboardMoreRow.roleFor(
          AppSpace.services,
          const ['performerFoxer'],
        ),
        'performers',
      );
      expect(
        LeaderboardMoreRow.roleFor(
          AppSpace.services,
          const ['performerFoxer', 'serviceFoxer'],
        ),
        'services',
      );
    });

    test('is events for an Organizer, who has no board of their own', () {
      expect(
        LeaderboardMoreRow.roleFor(AppSpace.organizer, const ['organizer']),
        'event',
      );
    });
  });

  testWidgets('tapping the row opens the board on that role', (tester) async {
    String? opened;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: LeaderboardMoreRow(space: AppSpace.venue),
          ),
        ),
        GoRoute(
          path: RouteNames.leaderboard,
          builder: (context, state) {
            opened = state.uri.queryParameters['role'];
            return const Scaffold(body: Text('opened'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith(() => _Session(const ['venueFoxer'])),
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

    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    expect(opened, 'venue');
  });
}
