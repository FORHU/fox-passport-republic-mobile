import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

Widget _app({
  required List<Ticket> tickets,
  required List<CatalogItem> picks,
  List<CatalogItem> foxers = const [],
  int unread = 0,
}) {
  final storage = MockStorageService();
  when(storage.readUserModel).thenReturn(null);

  return ProviderScope(
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      upcomingTicketsProvider.overrideWith((ref) async => tickets),
      notificationInboxProvider.overrideWith(
        (ref) async => NotificationInbox(
          notifications: const [],
          unreadCount: unread,
        ),
      ),
      catalogProvider.overrideWith((ref, q) async {
        final items = switch (q.kind) {
          CatalogKind.venues => picks,
          CatalogKind.foxers => foxers,
          _ => const <CatalogItem>[],
        };
        return CatalogPage(items: items, total: items.length);
      }),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(),
    ),
  );
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  testWidgets('shows home discovery sections and a compact upcoming ticket', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        tickets: [Ticket.sample()],
        picks: const [
          CatalogItem(
            id: 'v1',
            kind: CatalogKind.venues,
            title: 'Sky Hall',
            city: 'Davao City',
            price: 25000,
            billingRate: 'daily',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('IN 3 DAYS'), findsOneWidget);
    expect(find.text('Open ticket'), findsOneWidget);
    expect(find.text('Davao City'), findsOneWidget);
    expect(find.text('What are you planning?'), findsOneWidget);

    for (final category in ['Wedding', 'Birthday', 'Corporate', 'Social']) {
      expect(find.text(category), findsOneWidget);
    }

    expect(find.text('Venues near you'), findsOneWidget);
    expect(find.text('Foxers for your night'), findsOneWidget);
    expect(find.text('See all'), findsNWidgets(2));
    expect(find.text('Sky Hall'), findsWidgets);
    expect(find.text('₱25,000/day'), findsOneWidget);
    // The venue photo fills its 168-wide card rather than shrinking.
    expect(tester.getSize(find.byType(PhotoBox).first).width, 168);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lists Foxers as rows and badges the bell', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        tickets: const [],
        picks: const [],
        unread: 3,
        foxers: const [
          CatalogItem(
            id: 'f1',
            kind: CatalogKind.foxers,
            title: 'Rico Rival',
            rating: 5,
            roles: ['eventFoxer'],
            verified: true,
            online: true,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rico Rival'), findsOneWidget);
    expect(find.text('Event Foxer · 5.0'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.byTooltip('Message Rico Rival'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out on a small phone without overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(tickets: [Ticket.sample()], picks: const []));
    await tester.pumpAndSettle();

    final layoutError = tester.takeException();
    expect(layoutError, isNull);
  });
}
