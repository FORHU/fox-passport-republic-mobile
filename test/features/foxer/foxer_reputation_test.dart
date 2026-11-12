import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/features/foxer/presentation/widgets/foxer_reputation_panel.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/foxers/foxer_reputation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _reply({
  Object? star = 4.8,
  int reviews = 40,
  bool isNew = false,
  int bookings = 62,
  int replies = 96,
  int cancels = 2,
  List<String> labels = const ['Top rated', 'Fast responder', 'Reliable'],
}) =>
    {
      'success': true,
      'data': {
        'starRating': star,
        'reviewCount': reviews,
        'isNew': isNew,
        'completedBookings': bookings,
        'responseRatePercent': replies,
        'cancellationRatePercent': cancels,
        'isIdentityVerified': true,
        'labels': labels,
      },
    };

void main() {
  group('the model', () {
    test('reads Foxer since as a date', () {
      final json = (_reply()['data'] as Map).cast<String, dynamic>()
        ..['foxerSince'] = '2026-03-04T00:00:00.000Z';
      final r = FoxerReputation.fromJson(json);
      expect(r.foxerSince, DateTime.utc(2026, 3, 4));
      expect(
        FoxerReputation.fromJson(
          (_reply()['data'] as Map).cast<String, dynamic>(),
        ).foxerSince,
        isNull,
      );
    });

    test('reads the facts and labels', () {
      final r = FoxerReputation.fromJson(
        (_reply()['data'] as Map).cast<String, dynamic>(),
      );

      expect(r.starRating, 4.8);
      expect(r.reviewCount, 40);
      expect(r.completedBookings, 62);
      expect(r.responseRatePercent, 96);
      expect(r.cancellationRatePercent, 2);
      expect(r.isIdentityVerified, isTrue);
      expect(r.labels, ['Top rated', 'Fast responder', 'Reliable']);
      expect(r.isEmpty, isFalse);
    });

    test('a new Foxer has no star rating', () {
      final r = FoxerReputation.fromJson(
        (_reply(star: null, reviews: 2, isNew: true)['data'] as Map)
            .cast<String, dynamic>(),
      );

      expect(r.starRating, isNull);
      expect(r.isNew, isTrue);
    });

    test('keeps percentages between 0 and 100 and drops blank labels', () {
      final r = FoxerReputation.fromJson(const {
        'responseRatePercent': 140,
        'cancellationRatePercent': -5,
        'labels': ['Reliable', ' ', 3],
      });

      expect(r.responseRatePercent, 100);
      expect(r.cancellationRatePercent, 0);
      expect(r.labels, ['Reliable']);
    });

    test('has nothing to show with no bookings and no labels', () {
      expect(FoxerReputation.fromJson(const {}).isEmpty, isTrue);
    });
  });

  group('the repository', () {
    test('reads /foxer-score/:userId', () async {
      final api = _MockApi();
      when(() => api.get(ApiEndpoints.foxerScoreFor('f1')))
          .thenAnswer((_) async => _reply());

      final r = await FoxerRepository(api).reputation('f1');

      expect(r.completedBookings, 62);
      verify(() => api.get('/foxer-score/f1')).called(1);
    });

    test('refuses a reply with no data', () async {
      final api = _MockApi();
      when(() => api.get(any())).thenAnswer((_) async => {'success': true});

      expect(FoxerRepository(api).reputation('f1'), throwsFormatException);
    });
  });

  group('the panel', () {
    Future<void> show(
      WidgetTester tester,
      Future<FoxerReputation> Function() load,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            foxerReputationProvider.overrideWith((ref, id) => load()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: FoxerReputationPanel(userId: 'f1')),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    FoxerReputation reputation({
      int bookings = 62,
      List<String> labels = const ['Top rated', 'Fast responder', 'Reliable'],
    }) =>
        FoxerReputation.fromJson(
          (_reply(bookings: bookings, labels: labels)['data'] as Map)
              .cast<String, dynamic>(),
        );

    testWidgets('shows three facts and the earned labels', (tester) async {
      await show(tester, () async => reputation());

      expect(find.text('62'), findsOneWidget);
      expect(find.text('Bookings done'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget);
      expect(find.text('Replies in time'), findsOneWidget);
      expect(find.text('2%'), findsOneWidget);
      expect(find.text('Cancellations'), findsOneWidget);
      expect(find.text('Top rated'), findsOneWidget);
      expect(find.text('Fast responder'), findsOneWidget);
      expect(find.text('Reliable'), findsOneWidget);
    });

    testWidgets('never shows the 0 to 100 score', (tester) async {
      await show(tester, () async => reputation());

      expect(find.textContaining('Score'), findsNothing);
      expect(find.textContaining('/ 100'), findsNothing);
    });

    testWidgets('a label it does not know is shown as sent', (tester) async {
      await show(tester, () async => reputation(labels: ['Community pick']));

      expect(find.text('Community pick'), findsOneWidget);
    });

    testWidgets('takes no room when there is nothing to say', (tester) async {
      await show(tester, () async => reputation(bookings: 0, labels: []));

      expect(find.text('Bookings done'), findsNothing);
      expect(tester.getSize(find.byType(FoxerReputationPanel)), Size.zero);
    });

    testWidgets('takes no room when it cannot be loaded', (tester) async {
      await show(tester, () async => throw Exception('offline'));

      expect(find.text('Bookings done'), findsNothing);
      expect(tester.getSize(find.byType(FoxerReputationPanel)), Size.zero);
      expect(tester.takeException(), isNull);
    });
  });
}
