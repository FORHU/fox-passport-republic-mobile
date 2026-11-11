import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/foxer_passport.dart';
import 'package:flutter_template/features/passport/presentation/pages/foxer_passport_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/foxers/foxer_score.dart';
import 'package:flutter_template/shared/foxers/foxer_score_source.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

const _passport = FoxerPassport(
  path: 'venueFoxer',
  perks: [],
  badges: [],
);

const _score = FoxerScore(
  score: 82,
  breakdown: FoxerScoreBreakdown(
    rating: 38,
    volume: 15,
    responsiveness: 14,
    reliability: 13,
    trust: 2,
  ),
  starRating: 4.8,
  reviewCount: 40,
  isNew: false,
  completedBookings: 62,
  responseRatePercent: 96,
  cancellationRatePercent: 2,
  isIdentityVerified: true,
);

Future<void> _show(
  WidgetTester tester, {
  required Future<FoxerScore> Function() score,
}) async {
  tester.view
    ..physicalSize = const Size(900, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        foxerPassportProvider('venueFoxer')
            .overrideWith((ref) async => _passport),
        myFoxerScoreProvider.overrideWith((ref) => score()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FoxerPassportPage(path: 'venueFoxer'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a Foxer sees their own Foxer Score on their Passport',
      (tester) async {
    await _show(tester, score: () async => _score);

    expect(find.text('Foxer Score'), findsOneWidget);
    expect(find.text('82 / 100'), findsOneWidget);
    expect(find.textContaining('Only you see this score'), findsOneWidget);
    // The rest of the Passport is still there.
    expect(find.text('Perks'), findsOneWidget);
  });

  testWidgets('the Passport still works when the score cannot be loaded',
      (tester) async {
    await _show(tester, score: () async => throw Exception('offline'));

    expect(find.text('Foxer Score'), findsNothing);
    expect(find.text('Perks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
