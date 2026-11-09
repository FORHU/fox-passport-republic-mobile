import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/features/foxer/presentation/widgets/foxer_reputation_panel.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/foxers/foxer_reputation.dart';
import 'package:flutter_test/flutter_test.dart';

FoxerReputation _rep({Map<String, dynamic>? place, int bookings = 10}) =>
    FoxerReputation.fromJson({
      'starRating': 4.8,
      'reviewCount': 40,
      'completedBookings': bookings,
      'responseRatePercent': 96,
      'cancellationRatePercent': 2,
      'labels': const <String>[],
      if (place != null) 'leaderboard': place,
    });

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  group('the place', () {
    test('is read from the reply', () {
      final r = _rep(
        place: {'position': 3, 'role': 'venueFoxer', 'city': 'Manila'},
      );

      expect(
        r.place,
        const FoxerPlace(position: 3, role: 'venueFoxer', city: 'Manila'),
      );
    });

    test('is absent when the reply has none, or a bad one', () {
      expect(_rep().place, isNull);
      expect(FoxerPlace.tryParse(null), isNull);
      expect(
        FoxerPlace.tryParse(const {'position': 0, 'role': 'venueFoxer'}),
        isNull,
      );
      expect(FoxerPlace.tryParse(const {'position': 2}), isNull);
    });

    test('drops an empty city', () {
      final p = FoxerPlace.tryParse(
        const {'position': 1, 'role': 'gearFoxer', 'city': '  '},
      );

      expect(p!.city, isNull);
    });

    test('is enough to have something to show, with no bookings', () {
      final r = _rep(
        bookings: 0,
        place: {'position': 1, 'role': 'venueFoxer', 'city': null},
      );

      expect(r.isEmpty, isFalse);
    });
  });

  group('its words', () {
    test('the place, the kind of Foxer and the city', () async {
      final l10n = await _l10n();

      expect(
        foxerPlaceText(
          l10n,
          const FoxerPlace(position: 3, role: 'venueFoxer', city: 'Manila'),
        ),
        '#3 Venues in Manila',
      );
      expect(
        foxerPlaceText(
          l10n,
          const FoxerPlace(position: 1, role: 'eventFoxer', city: 'Davao'),
        ),
        '#1 Events in Davao',
      );
    });

    test('without a city', () async {
      final l10n = await _l10n();

      expect(
        foxerPlaceText(
          l10n,
          const FoxerPlace(position: 7, role: 'gearFoxer'),
        ),
        '#7 Gear',
      );
    });

    test('every board role has a name, and an unknown one still reads',
        () async {
      final l10n = await _l10n();

      String say(String role) => foxerPlaceText(
            l10n,
            FoxerPlace(position: 2, role: role, city: 'Manila'),
          );

      expect(say('serviceFoxer'), '#2 Services in Manila');
      expect(say('performerFoxer'), '#2 Performers in Manila');
      expect(say('providerFoxer'), '#2 Providers in Manila');
      expect(say('mystery'), '#2 · Manila');
      expect(
        foxerPlaceText(l10n, const FoxerPlace(position: 2, role: 'mystery')),
        '#2',
      );
    });
  });

  group('the panel', () {
    testWidgets('shows the place above the facts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foxerReputationProvider.overrideWith(
              (ref, id) async => _rep(
                place: {'position': 3, 'role': 'venueFoxer', 'city': 'Manila'},
              ),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: FoxerReputationPanel(userId: 'f1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('#3 Venues in Manila'), findsOneWidget);
      expect(find.text('Bookings done'), findsOneWidget);
    });

    testWidgets('shows no place line when they are not on a board',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foxerReputationProvider.overrideWith((ref, id) async => _rep()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: FoxerReputationPanel(userId: 'f1')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
      expect(find.text('Bookings done'), findsOneWidget);
    });
  });
}
