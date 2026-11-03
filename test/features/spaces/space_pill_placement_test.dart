import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Session extends AuthController {
  _Session(this.roles);

  final List<String> roles;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ada',
          roleType: roles,
        ),
      );
}

void main() {
  Future<GlobalKey<NavigatorState>> pump(
    WidgetTester tester, {
    required List<String> roles,
    Widget? row,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => _Session(roles)),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: const SpaceAppBar(title: 'Overview'),
            body: row ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    return navigator;
  }

  group('the space pill', () {
    testWidgets('is not in the top bar of a space, even with two roles', (
      tester,
    ) async {
      await pump(tester, roles: ['venueFoxer']);

      expect(find.byType(SpaceSwitchButton), findsNothing);
      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('is not in the top bar of a page opened over a tab', (
      tester,
    ) async {
      final navigator = await pump(tester, roles: ['venueFoxer']);

      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            appBar: SpaceAppBar(title: 'Team'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(SpaceSwitchButton), findsNothing);
    });
  });
}
