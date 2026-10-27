import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/bids_repository.dart';
import 'package:flutter_template/features/spaces/domain/bid.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/event_bids_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FakeBids extends BidsRepository {
  _FakeBids(this.rows, {this.refuses = false}) : super(_MockApi());

  final List<Bid> rows;
  final bool refuses;
  final calls = <String>[];

  @override
  Future<List<Bid>> forEvent(String eventId) async => rows;

  @override
  Future<void> accept(Bid bid) async {
    calls.add('accept ${bid.id}');
    if (refuses) throw const ServerException('Service is no longer available');
  }

  @override
  Future<void> reject(Bid bid) async => calls.add('reject ${bid.id}');
}

const _event = TeamTarget(isEvent: true, id: 'e1', name: 'Launch party');

const _pending = Bid(
  id: 'b1',
  isService: true,
  status: BidStatus.pending,
  provider: 'DJ Rex',
  offer: 'Club set',
  price: 5000,
  currency: 'PHP',
  slot: 'Music',
  message: 'Ten years playing weddings.',
);

const _accepted = Bid(
  id: 'b2',
  isService: false,
  status: BidStatus.accepted,
  provider: 'Lights Co',
  offer: 'Par cans',
  price: 800,
  currency: 'PHP',
  quantity: 4,
);

Future<_FakeBids> _pump(
  WidgetTester tester,
  List<Bid> rows, {
  bool refuses = false,
}) async {
  final repo = _FakeBids(rows, refuses: refuses);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bidsRepositoryProvider.overrideWithValue(repo),
        moneyFormatterProvider
            .overrideWithValue(const MoneyFormatter(currency: 'PHP')),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EventBidsPage(event: _event),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('reads a service bid and a gear bid', () {
    final service = Bid.tryParse(
      {
        'id': 'b1',
        'status': 'pending',
        'proposedPrice': '5000',
        'provider': {'name': 'DJ Rex'},
        'proposedService': {'name': 'Club set'},
        'targetRequirement': {'description': 'Music', 'currency': 'PHP'},
      },
      isService: true,
    );
    expect(service?.provider, 'DJ Rex');
    expect(service?.offer, 'Club set');
    expect(service?.price, 5000);
    expect(service?.slot, 'Music');

    final gear = Bid.tryParse(
      {
        'id': 'b2',
        'status': 'accepted',
        'proposedPrice': 800,
        'proposedQuantity': 4,
        'proposedAsset': {'name': 'Par cans'},
      },
      isService: false,
    );
    expect(gear?.status, BidStatus.accepted);
    expect(gear?.quantity, 4);
    expect(Bid.tryParse({'status': 'pending'}, isService: true), isNull);
  });

  testWidgets('shows who applied and what they ask', (tester) async {
    await _pump(tester, [_pending, _accepted]);

    expect(find.text('DJ Rex'), findsOneWidget);
    expect(find.text('Club set'), findsOneWidget);
    expect(find.textContaining('Music'), findsOneWidget);
    expect(find.text('Par cans × 4'), findsOneWidget);
    // Only the pending bid can be answered.
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await _pump(tester, []);

    expect(find.text('No applications yet'), findsOneWidget);
  });

  testWidgets('accepts a bid', (tester) async {
    final repo = await _pump(tester, [_pending]);

    await tester.tap(find.text('Accept'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Accepted. They are on the event.'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(repo.calls, ['accept b1']);
  });

  testWidgets('declines a bid', (tester) async {
    final repo = await _pump(tester, [_pending]);

    await tester.tap(find.text('Decline'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(repo.calls, ['reject b1']);
  });

  testWidgets('says why the API refused', (tester) async {
    await _pump(tester, [_pending], refuses: true);

    await tester.tap(find.text('Accept'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Service is no longer available'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
