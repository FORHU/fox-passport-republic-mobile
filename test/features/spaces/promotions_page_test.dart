import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/promotions_repository.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/promotion.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/promotions_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FakePromotions extends PromotionsRepository {
  _FakePromotions(this.rows) : super(_MockApi());

  List<Promotion> rows;
  final calls = <String>[];

  @override
  Future<List<Promotion>> mine() async => rows;

  @override
  Future<void> create(PromotionDraft draft) async {
    calls.add('create ${draft.toJson()}');
  }

  @override
  Future<void> setActive(String id, {required bool active}) async {
    calls.add('active $id $active');
  }

  @override
  Future<void> remove(String id) async {
    calls.add('remove $id');
    rows = [
      for (final r in rows)
        if (r.id != id) r,
    ];
  }
}

const _summer = Promotion(
  id: 'p1',
  name: 'Summer sale',
  isPercentage: true,
  value: 20,
  active: true,
  autoApply: true,
);

const _venue = SpaceListing(id: 'v1', name: 'The Loft', status: 'available');

Future<_FakePromotions> _pump(
  WidgetTester tester,
  List<Promotion> rows,
) async {
  final repo = _FakePromotions(rows);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promotionsRepositoryProvider.overrideWithValue(repo),
        myVenuesProvider.overrideWith((ref) async => [_venue]),
        moneyFormatterProvider
            .overrideWithValue(const MoneyFormatter(currency: 'PHP')),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PromotionsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('reads a promotion row', () {
    final p = Promotion.tryParse({
      'id': 'p1',
      'name': 'Fifty off',
      'discountType': 'fixed',
      'discountValue': 50,
      'active': false,
      'venueId': 'v1',
    });
    expect(p?.isPercentage, isFalse);
    expect(p?.value, 50);
    expect(p?.active, isFalse);
    expect(p?.venueId, 'v1');
    expect(Promotion.tryParse({'name': 'no id'}), isNull);
  });

  testWidgets('lists promotions with their discount', (tester) async {
    await _pump(tester, [_summer]);

    expect(find.text('Summer sale'), findsOneWidget);
    expect(find.textContaining('20% off'), findsOneWidget);
    expect(find.textContaining('automatic'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await _pump(tester, []);

    expect(find.text('No promotions yet'), findsOneWidget);
  });

  testWidgets('turns a promotion off', (tester) async {
    final repo = await _pump(tester, [_summer]);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repo.calls, ['active p1 false']);
  });

  testWidgets('removes a promotion after asking', (tester) async {
    final repo = await _pump(tester, [_summer]);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(repo.calls, ['remove p1']);
    expect(find.text('Summer sale'), findsNothing);
  });

  testWidgets('creates a promotion on the venue', (tester) async {
    final repo = await _pump(tester, []);

    await tester.tap(find.text('New promotion'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Launch week');
    await tester.enterText(fields.at(1), '15');
    await tester.pump();
    await tester.tap(find.text('Create promotion'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single, contains('Launch week'));
    expect(repo.calls.single, contains('percentage'));
    expect(repo.calls.single, contains('v1'));
  });
}
