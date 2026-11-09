import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/passport_more_row.dart';
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
