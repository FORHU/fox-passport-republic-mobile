import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/citizen_profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _Follows extends FollowRepository {
  _Follows() : super(_MockApi());

  @override
  Future<FollowStatus> status(String userId) async =>
      const FollowStatus(followers: 1234);
}

void main() {
  // The profile follows the screen: a narrow phone gets smaller parts, and a
  // phone set to a large font does not push it off the screen. Run under the
  // real theme, with the longest things a profile can show.
  for (final (width, textScale) in [
    (320.0, 1.0),
    (360.0, 1.0),
    (360.0, 1.5),
    (411.0, 1.0),
    (320.0, 2.0),
  ]) {
    testWidgets('lays out at $width wide with ${textScale}x text', (
      tester,
    ) async {
      tester.view
        ..physicalSize = Size(width, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Session.new),
            followRepositoryProvider.overrideWithValue(_Follows()),
            citizenProfileProvider.overrideWith(
              (ref, id) async => CitizenProfile.tryParse({
                'id': 'u1',
                'name': 'Fox Partner Villanueva',
                'username': 'fox_partner',
                'city': 'Makati',
                'country': 'Philippines',
                'roleType': [
                  'venueFoxer',
                  'eventFoxer',
                  'gearFoxer',
                  'serviceFoxer',
                  'investor',
                ],
                'createdAt': '2026-01-01T00:00:00Z',
                'passport': {
                  'paths': [
                    {'path': 'user', 'level': 12, 'currentXP': 1234},
                  ],
                },
                '_count': {'posts': 125},
              })!,
            ),
            citizenCountsProvider.overrideWith(
              (ref, id) async =>
                  const CitizenFollowCounts(followers: 1234, following: 567),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: CitizenProfilePage(userId: 'u1', onMessage: (_, __) async {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fox Partner Villanueva'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
    });
  }

  testWidgets('your own profile fits a narrow phone with large text',
      (tester) async {
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Session.new),
          citizenProfileProvider.overrideWith(
            (ref, id) async => CitizenProfile.tryParse({
              'id': 'me',
              'name': 'Fox Partner Villanueva',
              'bio': 'I host live music nights and pop-up markets in Manila.',
              'roleType': ['venueFoxer', 'eventFoxer', 'investor'],
            })!,
          ),
          citizenCountsProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const CitizenProfilePage(userId: 'me'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Edit profile'), findsOneWidget);
    // The account actions are in Settings, not on the profile.
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Verify your identity'), findsNothing);
  });
}
