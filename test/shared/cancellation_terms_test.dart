import 'package:flutter/material.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/policies/cancellation_terms.dart';
import 'package:flutter_test/flutter_test.dart';

/// mobile#502: Flexible (a refund and a deadline) or Non-refundable.
void main() {
  group('reading a venue policy', () {
    test('its earliest rule gives the refund and the deadline', () {
      expect(
        CancellationTerms.fromPolicy({
          'name': 'Flexible',
          'rules': [
            {'hoursBeforeEvent': 0, 'refundPercent': 0},
            {'hoursBeforeEvent': 168, 'refundPercent': 75},
          ],
        }),
        const CancellationTerms.flexible(refundPercent: 75, hoursBefore: 168),
      );
    });

    test('a Non-Refundable name, or no refund at all, is non-refundable', () {
      expect(
        CancellationTerms.fromPolicy({
          'name': 'Non-Refundable',
          'rules': <Object>[],
        }),
        const CancellationTerms.nonRefundable(),
      );
      expect(
        CancellationTerms.fromPolicy({
          'name': 'Strict',
          'rules': [
            {'hoursBeforeEvent': 0, 'refundPercent': 0},
          ],
        }),
        const CancellationTerms.nonRefundable(),
      );
    });

    test('nothing to read is null', () {
      expect(CancellationTerms.fromPolicy(null), isNull);
      expect(CancellationTerms.fromPolicy({'name': 'Flexible'}), isNull);
    });
  });

  test('the API body: a type, and for Flexible its refund and deadline', () {
    expect(
      const CancellationTerms.flexible(refundPercent: 50, hoursBefore: 48)
          .toJson(),
      {
        'cancellationType': 'Flexible',
        'flexibleRefundPercent': 50,
        'flexibleRefundHours': 48,
      },
    );
    expect(
      const CancellationTerms.nonRefundable().toJson(),
      {'cancellationType': 'Non-Refundable'},
    );
  });

  group('a venue', () {
    test('sends its terms, which win over an old policy id', () {
      const draft = VenueDraft(
        name: 'Sky Hall',
        cancellationPolicyId: 'old',
        cancellation: CancellationTerms.nonRefundable(),
      );
      final body = draft.toJson();
      expect(body['cancellationType'], 'Non-Refundable');
      expect(body.containsKey('cancellationPolicyId'), isFalse);
      expect(body.containsKey('flexibleRefundPercent'), isFalse);
    });

    test('without terms keeps sending its policy id, as before', () {
      const draft = VenueDraft(name: 'Sky Hall', cancellationPolicyId: 'p1');
      final body = draft.toJson();
      expect(body['cancellationPolicyId'], 'p1');
      expect(body.containsKey('cancellationType'), isFalse);
    });

    test('loaded to edit, shows the terms it has', () {
      final detail = VenueDetail.tryParse({
        'id': 'v1',
        'name': 'Sky Hall',
        'cancellationPolicy': {
          'name': 'Flexible',
          'rules': [
            {'hoursBeforeEvent': 48, 'refundPercent': 100},
            {'hoursBeforeEvent': 0, 'refundPercent': 0},
          ],
        },
      });
      expect(
        detail!.draft.cancellation,
        const CancellationTerms.flexible(hoursBefore: 48),
      );
    });
  });

  testWidgets('the terms in words: hours, then whole days', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(cancellationDeadline(l10n, 1), '1 hour');
    expect(cancellationDeadline(l10n, 24), '24 hours');
    expect(cancellationDeadline(l10n, 48), '2 days');
    expect(cancellationDeadline(l10n, 168), '7 days');
    expect(cancellationDeadline(l10n, 36), '36 hours');
    expect(
      cancellationTermsText(l10n, const CancellationTerms.flexible()),
      '100% refund if cancelled at least 24 hours before the booking.',
    );
    expect(
      cancellationTermsText(l10n, const CancellationTerms.nonRefundable()),
      'Non-refundable: no refund if the booking is cancelled.',
    );
  });
}
