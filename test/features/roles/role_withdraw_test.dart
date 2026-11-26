import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_withdraw_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/role_resubmit_page.dart';
import 'package:flutter_template/features/roles/presentation/pages/roles_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_template/shared/roles/role_request.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// api#367: an applicant withdraws a role application still under review
/// from the Become a Foxer page.

class _MockRepo extends Mock implements RoleApplicationRepository {}

const _user = UserEntity(id: 'u1', email: 'ada@example.com', name: 'Ada');

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(user: _user);
}

const _pending = RoleRequestSummary(
  id: 'r1',
  roleType: 'eventFoxer',
  status: 'pending',
);

RoleCatalogEntry _entry(String roleType) =>
    roleCatalog.firstWhere((r) => r.roleType == roleType);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  group('RoleRequestSummary', () {
    test('reads a withdrawn application as closed', () {
      final r = RoleRequestSummary.fromJson(const {
        'id': 'r1',
        'roleType': 'eventFoxer',
        'status': 'withdrawn',
      });

      expect(r.isWithdrawn, isTrue);
      expect(r.isOpen, isFalse);
      expect(r.isPending, isFalse);
    });

    test('counts pending and sent-back applications as open', () {
      expect(_pending.isOpen, isTrue);
      expect(
        const RoleRequestSummary(
          id: 'r2',
          roleType: 'eventFoxer',
          status: 'revision_requested',
        ).isOpen,
        isTrue,
      );
    });
  });

  group('requestTitle', () {
    test("names the card's own role, or the subsection's", () {
      final provider = _entry('providerFoxer');
      expect(
        requestTitle(
          provider,
          const RoleRequestSummary(
            id: 'p',
            roleType: 'providerFoxer',
            status: 'pending',
          ),
        ),
        provider.title,
      );
      expect(
        requestTitle(
          provider,
          const RoleRequestSummary(
            id: 'o',
            roleType: 'organizer',
            status: 'pending',
          ),
        ),
        'Event Coordinator',
      );
    });
  });

  group('RoleWithdrawController', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [roleApplicationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      // Kept alive for the test, as the page keeps it alive by watching it.
      c.listen(roleWithdrawProvider, (_, __) {});
      return c;
    }

    test('withdraws, and answers null', () async {
      when(() => repo.withdraw(any())).thenAnswer((_) async {});
      final c = container();

      final error = await c.read(roleWithdrawProvider.notifier).withdraw('r1');

      expect(error, isNull);
      verify(() => repo.withdraw('r1')).called(1);
      expect(c.read(roleWithdrawProvider), isNull);
    });

    test("answers with the API's reason when it refuses", () async {
      when(() => repo.withdraw(any())).thenThrow(
        const ServerException(
          "This application was already approved and can't be withdrawn",
          statusCode: 400,
        ),
      );
      final c = container();

      final error = await c.read(roleWithdrawProvider.notifier).withdraw('r1');

      expect(
        error,
        "This application was already approved and can't be withdrawn",
      );
    });

    test('answers empty for an error with nothing to show', () async {
      when(() => repo.withdraw(any())).thenThrow(Exception('socket'));
      final c = container();

      expect(
        await c.read(roleWithdrawProvider.notifier).withdraw('r1'),
        isEmpty,
      );
    });
  });

  group('the page', () {
    Future<void> open(
      WidgetTester tester,
      List<RoleRequestSummary> requests,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Session.new),
            myRoleRequestsProvider.overrideWith((ref) async => requests),
            roleApplicationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RolesPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openCard(WidgetTester tester, String roleType) async {
      final title = find.text(_entry(roleType).title);
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
    }

    /// Scrolls the role sheet down to [target]: it lists the role's duties
    /// and needs first, so its buttons start below a phone's screen.
    Future<void> scrollSheetTo(WidgetTester tester, Finder target) =>
        tester.scrollUntilVisible(
          target,
          200,
          scrollable: find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          ),
        );

    testWidgets('withdraws an application under review once confirmed', (
      tester,
    ) async {
      when(() => repo.withdraw(any())).thenAnswer((_) async {});
      await open(tester, const [_pending]);

      await openCard(tester, 'eventFoxer');
      await scrollSheetTo(tester, find.text('Withdraw application'));
      await tester.tap(find.text('Withdraw application'));
      await tester.pumpAndSettle();

      expect(
        find.text('Withdraw your Event Foxer application?'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Withdraw application'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repo.withdraw('r1')).called(1);
      expect(find.text('Application withdrawn'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('keeps it when the applicant changes their mind', (
      tester,
    ) async {
      await open(tester, const [_pending]);

      await openCard(tester, 'eventFoxer');
      await scrollSheetTo(tester, find.text('Withdraw application'));
      await tester.tap(find.text('Withdraw application'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.withdraw(any()));
    });

    testWidgets('withdraws one sent back for revision from its fix screen', (
      tester,
    ) async {
      when(() => repo.withdraw(any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myRoleRequestsProvider.overrideWith(
              (ref) async => const [
                RoleRequestSummary(
                  id: 'r9',
                  roleType: 'organizer',
                  status: 'revision_requested',
                  flaggedDocuments: ['validId1'],
                ),
              ],
            ),
            roleApplicationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Opened on top of a page, as the app opens it, so it can close.
            routerConfig: GoRouter(
              initialLocation: '/fix',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const Scaffold(body: Text('Roles')),
                  routes: [
                    GoRoute(
                      path: 'fix',
                      builder: (_, __) =>
                          const RoleResubmitPage(requestId: 'r9'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Withdraw application'));
      await tester.pumpAndSettle();
      expect(
        find.text('Withdraw your Event Coordinator application?'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Withdraw application'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repo.withdraw('r9')).called(1);
      expect(find.text('Application withdrawn'), findsOneWidget);
      // Back where it was opened from.
      expect(find.text('Roles'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('offers no Withdraw for a role not applied for', (
      tester,
    ) async {
      await open(tester, const []);

      await openCard(tester, 'eventFoxer');
      // The sheet's last button, so everything above it has been built.
      await scrollSheetTo(tester, find.byType(ElevatedButton));

      expect(find.text('Withdraw application'), findsNothing);
    });
  });
}
