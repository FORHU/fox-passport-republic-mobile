import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/passport/presentation/pages/passport_page.dart';
import 'package:flutter_template/features/profile/presentation/pages/citizen_profile_page.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'fox@example.com',
          name: 'Fox Partner',
          username: 'fox_partner',
          roleType: ['eventFoxer', 'investor'],
        ),
      );
}

class _Follows extends FollowRepository {
  _Follows() : super(_MockApi());

  @override
  Future<FollowStatus> status(String userId) async => const FollowStatus();
}

/// The same pieces the route puts under the Passport's top bar.
Widget _profile(BuildContext context, PassportSummary? summary) =>
    CitizenProfileView(
      userId: 'u1',
      overrides: summary == null
          ? null
          : CitizenOverrides(
              stamps: summary.stamps.length,
              badges: summary.badges.where((b) => b.earned).length,
            ),
      extraTabs: [
        CitizenExtraTab(
          label: 'Matches',
          builder: (_) => const PassportMatchesTab(),
        ),
        CitizenExtraTab(
          label: 'Earn',
          builder: (_) => const PassportEarnTab(),
        ),
      ],
    );

Future<GoRouter> _open(
  WidgetTester tester, {
  Size size = const Size(360, 800),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final storage = _MockStorage();
  when(storage.readUserModel).thenReturn(null);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const PassportPage(bodyBuilder: _profile),
      ),
      GoRoute(
        path: RouteNames.republicSaved,
        builder: (_, __) => const Scaffold(body: Text('SAVED SCREEN')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
        storageServiceProvider.overrideWithValue(storage),
        authControllerProvider.overrideWith(_Session.new),
        followRepositoryProvider.overrideWithValue(_Follows()),
        passportProvider.overrideWith((ref) async => PassportSummary.sample()),
        myMatchRequestsProvider
            .overrideWith((ref) async => <MatchRequestItem>[]),
        citizenProfileProvider.overrideWith(
          (ref, id) async => CitizenProfile.tryParse({
            'id': 'u1',
            'name': 'Fox Partner',
            'username': 'fox_partner',
            'roleType': ['eventFoxer', 'investor'],
          })!,
        ),
        citizenCountsProvider.overrideWith((ref, id) async => null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('the Passport is your profile, with no row of pill tabs', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Passport'), findsOneWidget);
    // The card others see, with no level or XP.
    expect(find.text('Fox Partner'), findsOneWidget);
    expect(find.text('@fox_partner'), findsOneWidget);
    expect(find.textContaining('Level'), findsNothing);
    expect(find.textContaining('XP'), findsNothing);
    expect(find.text('Edit profile'), findsOneWidget);
    // The profile's tabs, with the counts from your Passport.
    expect(find.text('Stamps (2)'), findsOneWidget);
    expect(find.textContaining('Badges ('), findsOneWidget);
    // The old row of pills is gone: Progress was its first.
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Matches and Earn are tabs on it', (tester) async {
    await _open(tester);

    await tester.ensureVisible(find.text('Matches'));
    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No requests yet'), findsOneWidget);

    await tester.ensureVisible(find.text('Earn'));
    await tester.tap(find.text('Earn'));
    await tester.pumpAndSettle();
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Saved is not in the top bar: it is a row in Settings', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byTooltip('Saved'), findsNothing);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('fits a narrow phone and scrolls to the end', (tester) async {
    await _open(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
