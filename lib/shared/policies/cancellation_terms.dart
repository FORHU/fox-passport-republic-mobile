import 'package:equatable/equatable.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';

/// A venue's cancellation terms in the two forms owners choose from
/// (mobile#502), as the API's `cancellationType`: **Flexible**, a refund of
/// [refundPercent] when cancelled at least [hoursBefore] hours before the
/// booking, or **Non-refundable**.
class CancellationTerms extends Equatable {
  const CancellationTerms.flexible({
    this.refundPercent = defaultPercent,
    this.hoursBefore = defaultHours,
  }) : nonRefundable = false;

  const CancellationTerms.nonRefundable()
      : nonRefundable = true,
        refundPercent = 0,
        hoursBefore = 0;

  /// What the web starts a Flexible policy on.
  static const defaultPercent = 100;
  static const defaultHours = 24;

  /// The refunds and deadlines an owner picks from.
  static const percentChoices = [50, 75, 100];
  static const hourChoices = [24, 48, 168];

  final bool nonRefundable;
  final int refundPercent;
  final int hoursBefore;

  /// The API's `cancellationType`.
  String get apiType => nonRefundable ? 'Non-Refundable' : 'Flexible';

  /// The body fields that set these terms on a venue.
  Map<String, Object> toJson() => {
        'cancellationType': apiType,
        if (!nonRefundable) ...{
          'flexibleRefundPercent': refundPercent,
          'flexibleRefundHours': hoursBefore,
        },
      };

  /// Reads a venue's `cancellationPolicy` (a name and its rules), as the web
  /// does: one named non-refundable, or one with no refund at all, is
  /// Non-refundable; otherwise its earliest rule gives the refund and the
  /// deadline. Null when there is no policy to read.
  static CancellationTerms? fromPolicy(Object? raw) {
    if (raw is! Map) return null;
    final name = '${raw['name'] ?? ''}'.toLowerCase();
    if (name.contains('non-refundable') || name.contains('non refundable')) {
      return const CancellationTerms.nonRefundable();
    }
    final rules = [
      for (final r in raw['rules'] is List ? raw['rules'] as List : const [])
        if (r is Map &&
            r['hoursBeforeEvent'] is num &&
            r['refundPercent'] is num)
          (
            hours: (r['hoursBeforeEvent'] as num).toInt(),
            percent: (r['refundPercent'] as num).toInt(),
          ),
    ]..sort((a, b) => b.hours.compareTo(a.hours));
    if (rules.isEmpty) return null;
    final top = rules.first;
    if (top.percent <= 0) return const CancellationTerms.nonRefundable();
    return CancellationTerms.flexible(
      refundPercent: top.percent,
      hoursBefore: top.hours,
    );
  }

  @override
  List<Object?> get props => [nonRefundable, refundPercent, hoursBefore];
}

/// A deadline in hours as people say it: whole days from two days up
/// ("7 days"), hours below that ("24 hours").
String cancellationDeadline(AppLocalizations l10n, int hours) =>
    hours >= 48 && hours % 24 == 0
        ? l10n.cancelTermsDays(hours ~/ 24)
        : l10n.cancelTermsHours(hours);

/// The terms in one sentence, for the owner and for the citizen booking.
String cancellationTermsText(AppLocalizations l10n, CancellationTerms t) =>
    t.nonRefundable
        ? l10n.cancelTermsNonRefundable
        : l10n.cancelTermsFlexible(
            t.refundPercent,
            cancellationDeadline(l10n, t.hoursBefore),
          );
