import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/l10n/generated/app_localizations_en.dart';
import 'package:flutter_template/shared/tour/citizen_tour.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the steps', () {
    final steps = citizenTourSteps(AppLocalizationsEn());

    test('are five, one per bottom tab, in the order of the bar', () {
      expect(steps, hasLength(5));
      expect(
        [for (final s in steps) s.target],
        [for (var i = 0; i < 5; i++) citizenTourTarget(i)],
      );
    });

    test('say what each tab is for', () {
      expect(
        [for (final s in steps) s.title],
        [
          "Find what's on",
          'Join the conversation',
          'Your tickets live here',
          'Talk to Foxers',
          'Your progress',
        ],
      );
    });

    test('promise nothing the app does not have yet', () {
      final text = [for (final s in steps) '${s.title} ${s.body}'].join(' ');
      for (final word in ['Coins', 'rank', 'achievement', 'referral']) {
        expect(text.contains(word), isFalse, reason: word);
      }
    });
  });

  group('the keys', () {
    test('are the same key for the same tab, and different between tabs', () {
      expect(citizenTabKey(2), same(citizenTabKey(2)));
      expect(citizenTabKey(1), isNot(same(citizenTabKey(2))));
    });

    test('are not the Foxer spaces tab keys', () {
      // A space bar and this bar can be in the tree together.
      expect(citizenTourTarget(0), isNot('tab-0'));
    });
  });

  test('it is remembered per account', () {
    expect(citizenTourSeenKey('a'), isNot(citizenTourSeenKey('b')));
    expect(citizenTourSeenKey(null), 'citizenTourSeen.anon');
  });

  testWidgets('without saved settings it is not shown', (tester) async {
    late bool shown;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async =>
                  shown = await offerCitizenTour(context, ref),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(shown, isFalse);
    expect(find.text("Find what's on"), findsNothing);
  });
}
