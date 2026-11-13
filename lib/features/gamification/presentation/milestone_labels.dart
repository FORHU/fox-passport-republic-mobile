import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:intl/intl.dart';

/// A whole number in the viewer's locale: 12,500.
String milestoneNumber(BuildContext context, int n) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format(n);

/// "5 bookings", "3 cities", "₱20,000": [n] of what the track counts.
String milestoneUnitLabel(BuildContext context, Milestone m, int n) {
  final l10n = context.l10n;
  return switch (m.counter) {
    'booked_events' => l10n.milestonesUnitBooked(n),
    'attended_events' => l10n.milestonesUnitAttended(n),
    'cities' => l10n.milestonesUnitCities(n),
    'venues' => l10n.milestonesUnitVenues(n),
    'reviews' => l10n.milestonesUnitReviews(n),
    'spend' => l10n.milestonesUnitSpend(milestoneNumber(context, n)),
    _ => milestoneNumber(context, n),
  };
}

/// "2 more bookings", "₱5,000 more": what is left to reach the next tier.
String milestoneMoreLabel(BuildContext context, Milestone m, int n) {
  final l10n = context.l10n;
  return switch (m.counter) {
    'booked_events' => l10n.milestonesMoreBooked(n),
    'attended_events' => l10n.milestonesMoreAttended(n),
    'cities' => l10n.milestonesMoreCities(n),
    'venues' => l10n.milestonesMoreVenues(n),
    'reviews' => l10n.milestonesMoreReviews(n),
    'spend' => l10n.milestonesMoreSpend(milestoneNumber(context, n)),
    _ => l10n.milestonesMoreCount(milestoneNumber(context, n)),
  };
}

/// "2 more", or "₱5,000 more" for money: what is left, without naming the
/// thing, for a line that already says which track it is on.
String milestoneShortMoreLabel(BuildContext context, Milestone m, int n) =>
    m.isMoney
        ? milestoneMoreLabel(context, m, n)
        : context.l10n.milestonesMoreCount(milestoneNumber(context, n));

/// What the count is of, in one word for the pill under the ring: "booked",
/// "attended", "cities", "venues", "reviews" or "spent".
String milestoneWord(BuildContext context, Milestone m) {
  final l10n = context.l10n;
  return switch (m.counter) {
    'booked_events' => l10n.milestonesWordBooked,
    'attended_events' => l10n.milestonesWordAttended,
    'cities' => l10n.milestonesWordCities,
    'venues' => l10n.milestonesWordVenues,
    'reviews' => l10n.milestonesWordReviews,
    'spend' => l10n.milestonesWordSpent,
    _ => '',
  };
}
