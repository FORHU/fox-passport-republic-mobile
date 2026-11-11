import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/onboarding/onboarding_repository.dart';
import 'package:flutter_template/shared/tour/citizen_tour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockOnboarding extends Mock implements OnboardingRepository {}

// The citizen tour and the server: a tour on record is not replayed, a new
// account sees it and the server is told when it closes.
void main() {
  late _MockOnboarding onboarding;
  late SharedPreferences prefs;
  bool? shown;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    onboarding = _MockOnboarding();
    shown = null;
    when(() => onboarding.complete(any()))
        .thenAnswer((_) async => const StepReward(coins: 20));
  });

  Future<void> open(WidgetTester tester, {bool force = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onboardingRepositoryProvider.overrideWithValue(onboarding),
          currentUserIdProvider.overrideWithValue('u1'),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async =>
                  shown = await offerCitizenTour(context, ref, force: force),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('a tour the server has on record is not played again',
      (tester) async {
    when(() => onboarding.completedSteps())
        .thenAnswer((_) async => {OnboardingStep.intro});

    await open(tester);

    expect(shown, isFalse);
    expect(find.text("Find what's on"), findsNothing);
    verifyNever(() => onboarding.complete(any()));
    // Remembered here too, so the server is not asked on every visit.
    expect(prefs.getBool(citizenTourSeenKey('u1')), isTrue);
  });

  testWidgets('a new account sees it, and the server is told when it closes',
      (tester) async {
    when(() => onboarding.completedSteps()).thenAnswer((_) async => {});

    await open(tester);
    expect(find.text("Find what's on"), findsOneWidget);
    verifyNever(() => onboarding.complete(any()));

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(shown, isTrue);
    verify(() => onboarding.complete(OnboardingStep.intro)).called(1);
  });

  testWidgets('when the server cannot be asked the tour still plays',
      (tester) async {
    when(() => onboarding.completedSteps()).thenThrow(Exception('offline'));

    await open(tester);

    expect(find.text("Find what's on"), findsOneWidget);
  });

  testWidgets('a failure to report is ignored', (tester) async {
    when(() => onboarding.completedSteps()).thenAnswer((_) async => {});
    when(() => onboarding.complete(any())).thenThrow(Exception('offline'));

    await open(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(shown, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a replay from Settings plays and reports without asking',
      (tester) async {
    await prefs.setBool(citizenTourSeenKey('u1'), true);

    await open(tester, force: true);
    expect(find.text("Find what's on"), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    verifyNever(() => onboarding.completedSteps());
    verify(() => onboarding.complete(OnboardingStep.intro)).called(1);
  });
}
