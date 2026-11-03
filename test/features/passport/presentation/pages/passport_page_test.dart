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
              level: summary.level,
              xp: summary.totalXp,
              progress: summary.progress,
              xpText: passportXpText(AppLocalizations.of(context)!, summary),
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
    // The card others see, with your Passport level and XP.
    expect(find.text('Fox Partner'), findsOneWidget);
    expect(find.text('@fox_partner'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('15 XP · Level 2 at 50'), findsOneWidget);
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

  testWidgets('Saved is an icon in the top bar and opens the saved posts', (
    tester,
  ) async {
    final router = await _open(tester);

    await tester.tap(find.byTooltip('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('SAVED SCREEN'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('SAVED SCREEN'), findsNothing);
    expect(find.text('Fox Partner'), findsOneWidget);
  });

  testWidgets('fits a narrow phone and scrolls to the end', (tester) async {
    await _open(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('PassportSummary', () {
    test('follows the API level curve', () {
      expect(PassportSummary.xpRequiredForLevel(1), 0);
      expect(PassportSummary.xpRequiredForLevel(2), 1000);
      expect(PassportSummary.xpRequiredForLevel(3), 2150);
    });

    test('works out level and progress from total XP', () {
      final s = PassportSummary.fromTotalXp(
        totalXp: 1575,
        stamps: const [],
        badges: const [],
      );
      expect(s.level, 2);
      expect(s.levelStartXp, 1000);
      expect(s.nextLevelXp, 2150);
      expect(s.progress, closeTo(0.5, 0.01));
    });
  });
}
