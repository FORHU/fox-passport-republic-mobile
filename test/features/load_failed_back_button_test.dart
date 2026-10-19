import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/features/event/data/event_repository.dart';
import 'package:flutter_template/features/event/presentation/pages/event_detail_page.dart';
import 'package:flutter_template/features/venue/data/venue_repository.dart';
import 'package:flutter_template/features/venue/presentation/pages/venue_detail_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _event = CatalogItem(
  id: 'ev1',
  kind: CatalogKind.events,
  title: 'Garden Birthday',
);
const _venue = CatalogItem(
  id: 'v1',
  kind: CatalogKind.venues,
  title: 'Sky Hall',
);

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
      retry: (_, __) => null,
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('the event page, when it cannot load, still has a named Back', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const EventDetailPage(item: _event), [
        eventPackageProvider
            .overrideWith((ref, item) async => throw Exception('offline')),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load this event."), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('the venue page, when it cannot load, still has a named Back', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const VenueDetailPage(item: _venue), [
        venueDetailProvider
            .overrideWith((ref, item) async => throw Exception('offline')),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load this venue."), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
