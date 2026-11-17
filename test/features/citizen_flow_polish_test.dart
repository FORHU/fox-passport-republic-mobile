import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/roles_page.dart';
import 'package:flutter_template/features/search/presentation/pages/search_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/roles/role_request.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u1', email: 'a@b.co', name: 'Ada'),
      );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppConfig.instance = const AppConfig.dev();
  });

  testWidgets('pull to refresh on Roles waits for the data it reloads', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var loads = 0;
    final second = Completer<List<RoleRequestSummary>>();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          authControllerProvider.overrideWith(_Session.new),
          myRoleRequestsProvider.overrideWith((ref) {
            loads++;
            return loads == 1
                ? Future.value(const <RoleRequestSummary>[])
                : second.future;
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RolesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 800);
    // Long enough for the pull to settle: the spinner must still be there,
    // because the new data has not arrived.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(loads, 2);

    second.complete(const <RoleRequestSummary>[]);
    await tester.pumpAndSettle();

    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('a new Search link starts from the default order again', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final queries = <CatalogQuery>[];
    Widget app(CatalogKind kind) => ProviderScope(
          retry: (_, __) => null,
          overrides: [
            catalogProvider.overrideWith((ref, q) async {
              queries.add(q);
              return const CatalogPage(items: [], total: 0);
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SearchPage(initialKind: kind),
          ),
        );

    await tester.pumpWidget(app(CatalogKind.venues));
    await tester.pumpAndSettle();

    // Sort venues by price through the filter sheet.
    await tester.tap(find.byIcon(Icons.tune_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort by'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: low to high').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(queries.last.sortBy, 'price_asc');

    // A deep link to another kind, then back to venues.
    await tester.pumpWidget(app(CatalogKind.foxers));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(CatalogKind.venues));
    await tester.pumpAndSettle();

    expect(queries.last.kind, CatalogKind.venues);
    expect(queries.last.sortBy, isNull);
  });
}
