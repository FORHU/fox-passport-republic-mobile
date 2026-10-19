import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/features/event/presentation/pages/scheduled_event_detail_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

CatalogItem _event(String? category) => CatalogItem(
      id: 'ev1',
      kind: CatalogKind.events,
      title: 'Garden Birthday',
      city: 'Cebu City',
      category: category,
    );

Future<GoRouter> _open(
  WidgetTester tester,
  CatalogItem item, {
  bool mock = false,
}) async {
  AppConfig.instance = AppConfig.dev(useMock: mock);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/event', extra: item),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/event',
        builder: (context, state) =>
            ScheduledEventDetailPage(item: state.extra! as CatalogItem),
      ),
      GoRoute(
        path: '/occasion/:name',
        builder: (context, state) =>
            Scaffold(body: Text('OCCASION ${state.pathParameters['name']}')),
      ),
      GoRoute(
        path: RouteNames.allCategories,
        builder: (context, state) => const Scaffold(body: Text('ALL')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        displayCurrencyProvider.overrideWithValue('PHP'),
        fxRatesProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('ScheduledEventDetailPage', () {
    testWidgets('plans something like it on the matching occasion',
        (tester) async {
      await _open(tester, _event('birthday'));

      expect(find.text('Garden Birthday'), findsOneWidget);
      await tester.tap(find.text('Plan something like this'));
      await tester.pumpAndSettle();

      expect(find.text('OCCASION birthday'), findsOneWidget);
    });

    testWidgets('falls back to all categories for an unknown category',
        (tester) async {
      await _open(tester, _event('tea party'));

      await tester.tap(find.text('Plan something like this'));
      await tester.pumpAndSettle();

      expect(find.text('ALL'), findsOneWidget);
    });

    testWidgets('can be saved and unsaved in mock mode', (tester) async {
      await _open(tester, _event('wedding'), mock: true);

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    });
  });
}
