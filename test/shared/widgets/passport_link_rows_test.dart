import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/passport_link_rows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> _pump(WidgetTester tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: Column(children: [SavedRow()]),
        ),
      ),
      GoRoute(
        path: RouteNames.republicSaved,
        builder: (_, __) => const Text('saved screen'),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('Saved opens your saved posts', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(find.text('saved screen'), findsOneWidget);
  });
}
