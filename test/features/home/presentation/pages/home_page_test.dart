import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

const _categories = [
  CategorySummary(name: 'birthday', count: 34, isEventCategory: true),
  CategorySummary(name: 'wedding', count: 28, isEventCategory: true),
  CategorySummary(name: 'corporate', count: 19, isEventCategory: true),
  CategorySummary(name: 'social', count: 12, isEventCategory: true),
  CategorySummary(name: 'other', count: 7, isEventCategory: true),
  CategorySummary(
    name: 'photography',
    count: 15,
    isEventCategory: false,
    services: 15,
  ),
  CategorySummary(name: 'dj', count: 9, isEventCategory: false, services: 9),
  CategorySummary(name: 'garden', count: 5, isEventCategory: false, venues: 5),
];

Widget _app({
  List<Ticket> tickets = const [],
  Future<List<CategorySummary>> Function()? categories,
  List<CatalogItem> soon = const [],
  bool soonFails = false,
  int unread = 0,
}) {
  final storage = MockStorageService();
  when(storage.readUserModel).thenReturn(null);
  when(() => storage.getString(any())).thenReturn(null);
  when(() => storage.setString(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    // A failed section stays failed here; Riverpod would retry it itself.
    retry: (_, __) => null,
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      upcomingTicketsProvider.overrideWith((ref) async => tickets),
      categoriesProvider.overrideWith(
        (ref) => (categories ?? () async => _categories)(),
      ),
      notificationInboxProvider.overrideWith(
        (ref) async => NotificationInbox(
          notifications: const [],
          unreadCount: unread,
        ),
      ),
      catalogProvider.overrideWith((ref, q) async {
        if (soonFails) throw Exception('offline');
        return CatalogPage(items: soon, total: soon.length);
      }),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(),
    ),
  );
}

void _phone(WidgetTester tester, {Size size = const Size(800, 2000)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  testWidgets('shows the occasions with live counts, most bookable first', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('What are you planning?'), findsOneWidget);
    for (final name in [
      'Birthday',
      'Wedding',
      'Corporate',
      'Social',
      'Other',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('34 ideas'), findsOneWidget);
    expect(find.text('7 ideas'), findsOneWidget);
    // photography, dj and garden: three categories behind "All".
    expect(find.text('3 more'), findsOneWidget);

    // Birthday (34) sits above Wedding (28).
    final birthday = tester.getTopLeft(find.text('Birthday'));
    final wedding = tester.getTopLeft(find.text('Wedding'));
    expect(birthday.dx, lessThan(wedding.dx));
  });

  testWidgets(
      'draws the occasions at once, without counts, when the call '
      'fails', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(categories: () async => throw Exception('offline')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wedding'), findsOneWidget);
    expect(find.textContaining('ideas'), findsNothing);
    // No error box, no apology.
    expect(find.text('Try again'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"book just one thing" lists venues then the busiest services', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Or book just one thing'), findsOneWidget);
    expect(find.text('Venues'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('DJ'), findsOneWidget);
  });

  testWidgets('leaves "book just one thing" out when there is nothing', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(categories: () async => const []));
    await tester.pumpAndSettle();

    expect(find.text('Or book just one thing'), findsNothing);
  });

  testWidgets('shows happening soon with a date badge', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        soon: [
          CatalogItem(
            id: 'e1',
            kind: CatalogKind.events,
            title: 'Night Market',
            city: 'Baguio',
            eventStartAt: DateTime(2099, 10, 24, 18),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happening soon near you'), findsOneWidget);
    expect(find.text('Night Market'), findsOneWidget);
    expect(find.text('OCT'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('leaves happening soon out when there are no events', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Happening soon near you'), findsNothing);
  });

  testWidgets('hides happening soon, heading included, when it fails', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(soonFails: true));
    await tester.pumpAndSettle();

    expect(find.text('Happening soon near you'), findsNothing);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('shows the strip for an upcoming booking and badges the bell', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(tickets: [Ticket.sample()], unread: 3));
    await tester.pumpAndSettle();

    expect(find.text('IN 3 DAYS'), findsOneWidget);
    expect(find.text('Open ticket'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no strip and no error without a booking', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Open ticket'), findsNothing);
  });

  testWidgets('has no Foxer pitch or empty boxes', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(categories: () async => const []));
    await tester.pumpAndSettle();

    expect(find.text('Become one'), findsNothing);
    expect(find.textContaining('No Foxers'), findsNothing);
    expect(find.text('Venues near you'), findsNothing);
  });

  testWidgets('lays out on a small phone without overflow', (tester) async {
    _phone(tester, size: const Size(360, 640));
    await tester.pumpWidget(_app(tickets: [Ticket.sample()]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
