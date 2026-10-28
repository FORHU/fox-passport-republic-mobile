import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/bids_repository.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/open_slot.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/open_slots_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FakeBids extends BidsRepository {
  _FakeBids(this.events, {this.refuses = false}) : super(_MockApi());

  final List<OpenSlotEvent> events;
  final bool refuses;
  final sent = <Map<String, dynamic>>[];

  @override
  Future<List<OpenSlotEvent>> openSlots() async => events;

  @override
  Future<void> submitService(ServiceBidDraft draft) async {
    if (refuses) throw const ServerException('You must be a Talent Foxer');
    sent.add(draft.toJson());
  }
}

const _slot = OpenSlot(
  id: 's1',
  price: 3000,
  currency: 'PHP',
  description: 'Live band',
);

const _event = OpenSlotEvent(
  id: 'e1',
  name: 'Launch party',
  city: 'Manila',
  host: 'Ada',
  slots: [_slot],
);

const _service = SpaceListing(id: 'srv1', name: 'Acoustic set', status: 'ok');

Future<_FakeBids> _pump(
  WidgetTester tester,
  List<OpenSlotEvent> events, {
  bool refuses = false,
  List<SpaceListing> services = const [_service],
}) async {
  final repo = _FakeBids(events, refuses: refuses);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bidsRepositoryProvider.overrideWithValue(repo),
        myServicesProvider.overrideWith((ref) async => services),
        moneyFormatterProvider
            .overrideWithValue(const MoneyFormatter(currency: 'PHP')),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OpenSlotsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('keeps only the spots that are still open', () {
    final event = OpenSlotEvent.tryParse({
      'id': 'e1',
      'name': 'Launch party',
      'targetCity': 'Manila',
      'host': {'name': 'Ada'},
      'template': {
        'templateServices': [
          {'id': 's1', 'description': 'DJ', 'agreedPrice': '2500'},
          {'id': 's2', 'description': 'Band', 'matched': true},
        ],
      },
    });
    expect(event?.slots.map((s) => s.id), ['s1']);
    expect(event?.slots.single.price, 2500);
    expect(event?.host, 'Ada');

    // Nothing open, nothing to show.
    expect(
      OpenSlotEvent.tryParse({
        'id': 'e2',
        'template': {
          'templateServices': [
            {'id': 's3', 'matched': true},
          ],
        },
      }),
      isNull,
    );
  });

  test('the draft names the spot, the service and the price', () {
    const draft = ServiceBidDraft(
      eventId: 'e1',
      slotId: 's1',
      serviceId: 'srv1',
      price: 2800,
      message: '  Ten years  ',
    );
    expect(draft.toJson(), {
      'eventId': 'e1',
      'eventTemplateServiceId': 's1',
      'proposedServiceId': 'srv1',
      'proposedPrice': 2800,
      'message': 'Ten years',
    });
  });

  testWidgets('lists events with their open spots', (tester) async {
    await _pump(tester, [_event]);

    expect(find.text('Launch party'), findsOneWidget);
    expect(find.text('Live band'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await _pump(tester, []);

    expect(find.text('No open slots right now'), findsOneWidget);
  });

  testWidgets('applies with the chosen service and price', (tester) async {
    final repo = await _pump(tester, [_event]);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    // The price starts at what the host set aside.
    expect(find.text('3000'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '2800');
    await tester.pump();
    await tester.tap(find.text('Send application'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Application sent.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(repo.sent, hasLength(1));
    expect(repo.sent.single['proposedPrice'], 2800);
    expect(repo.sent.single['proposedServiceId'], 'srv1');
    expect(repo.sent.single['eventTemplateServiceId'], 's1');
  });

  testWidgets('asks for a service first when there is none', (tester) async {
    final repo = await _pump(tester, [_event], services: const []);

    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('List a service first.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(repo.sent, isEmpty);
  });

  testWidgets('says why the API refused', (tester) async {
    await _pump(tester, [_event], refuses: true);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send application'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('You must be a Talent Foxer'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
