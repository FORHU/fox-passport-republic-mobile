import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/foxers/foxer_score.dart';
import 'package:flutter_template/shared/foxers/foxer_score_source.dart';
import 'package:flutter_template/shared/widgets/foxer_score_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _reply({
  int score = 82,
  bool isNew = false,
  double star = 4.8,
}) =>
    {
      'success': true,
      'data': {
        'foxerScore': score,
        'breakdown': {
          'ratingScore': 38.5,
          'volumeScore': 15,
          'responsivenessScore': 14,
          'reliabilityScore': 12.5,
          'trustScore': 2,
        },
        'operationalMetrics': {
          'starRating': star,
          'rawReviewCount': isNew ? 2 : 40,
          'isNew': isNew,
          'bayesianRating': 4.6,
          'completedBookings': 62,
          'responsivenessRate': 0.96,
          'cancellationRate': 0.02,
          'isIdentityVerified': true,
          'foxerLevel': 12,
        },
      },
    };

FoxerScore _score({int score = 82, bool isNew = false}) => FoxerScore.fromJson(
      (_reply(score: score, isNew: isNew)['data'] as Map)
          .cast<String, dynamic>(),
    );

void main() {
  group('the model', () {
    test('reads the score, its five parts and the facts', () {
      final s = _score();

      expect(s.score, 82);
      expect(s.breakdown.rating, 38.5);
      expect(s.breakdown.volume, 15);
      expect(s.breakdown.responsiveness, 14);
      expect(s.breakdown.reliability, 12.5);
      expect(s.breakdown.trust, 2);
      expect(s.starRating, 4.8);
      expect(s.reviewCount, 40);
      expect(s.completedBookings, 62);
      expect(s.responseRatePercent, 96);
      expect(s.cancellationRatePercent, 2);
      expect(s.isIdentityVerified, isTrue);
    });

    test('the part maximums add up to 100', () {
      expect(
        FoxerScoreBreakdown.maxRating +
            FoxerScoreBreakdown.maxVolume +
            FoxerScoreBreakdown.maxResponsiveness +
            FoxerScoreBreakdown.maxReliability +
            FoxerScoreBreakdown.maxTrust,
        100,
      );
    });

    test('keeps the score and the percentages in range', () {
      final s = FoxerScore.fromJson(const {
        'foxerScore': 140,
        'operationalMetrics': {
          'responsivenessRate': 1.4,
          'cancellationRate': -0.2,
        },
      });

      expect(s.score, 100);
      expect(s.responseRatePercent, 100);
      expect(s.cancellationRatePercent, 0);
    });

    test('survives a reply with nothing in it', () {
      final s = FoxerScore.fromJson(const {});

      expect(s.score, 0);
      expect(s.breakdown.rating, 0);
      expect(s.isNew, isFalse);
    });
  });

  group('the source', () {
    test('reads /foxer-score/me', () async {
      final api = _MockApi();
      when(() => api.get(ApiEndpoints.foxerScoreMe))
          .thenAnswer((_) async => _reply());

      final s = await FoxerScoreSource(api).mine();

      expect(s.score, 82);
      verify(() => api.get('/foxer-score/me')).called(1);
    });

    test('refuses a reply with no data', () async {
      final api = _MockApi();
      when(() => api.get(any())).thenAnswer((_) async => {'success': true});

      expect(FoxerScoreSource(api).mine(), throwsFormatException);
    });
  });

  group('the card', () {
    Future<void> show(
      WidgetTester tester,
      Future<FoxerScore> Function() load,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [myFoxerScoreProvider.overrideWith((ref) => load())],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: FoxerScoreCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the score out of 100 and each part of it',
        (tester) async {
      await show(tester, () async => _score());

      expect(find.text('Foxer Score'), findsOneWidget);
      expect(find.text('82 / 100'), findsOneWidget);
      expect(find.text('38.5 / 45'), findsOneWidget);
      expect(find.text('15 / 20'), findsOneWidget);
      expect(find.text('14 / 15'), findsOneWidget);
      expect(find.text('12.5 / 15'), findsOneWidget);
      expect(find.text('2 / 5'), findsOneWidget);
      for (final part in [
        'Rating',
        'Volume',
        'Responsiveness',
        'Reliability',
        'Trust',
      ]) {
        expect(find.text(part), findsOneWidget, reason: part);
      }
    });

    testWidgets('shows the facts behind it, and says only the Foxer sees it',
        (tester) async {
      await show(tester, () async => _score());

      expect(find.textContaining('Guest rating'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.textContaining('Bookings done'), findsOneWidget);
      expect(find.textContaining('96%'), findsOneWidget);
      expect(find.textContaining('2%'), findsOneWidget);
      expect(find.textContaining('Only you see this score'), findsOneWidget);
    });

    testWidgets('a new Foxer shows "New" in place of a star rating',
        (tester) async {
      await show(tester, () async => _score(isNew: true));

      expect(find.textContaining('New'), findsOneWidget);
      expect(find.textContaining('4.8'), findsNothing);
    });

    testWidgets('takes no room until it loads, or if it fails', (tester) async {
      await show(tester, () async => throw Exception('offline'));

      expect(find.text('Foxer Score'), findsNothing);
      expect(tester.getSize(find.byType(FoxerScoreCard)), Size.zero);
      expect(tester.takeException(), isNull);
    });
  });
}
