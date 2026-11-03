import 'package:flutter/material.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';

/// The first-time tour of a space, one list of cards per bottom-bar tab, in
/// the order of the tabs.
List<List<TourStep>> spaceTourSteps(
  AppLocalizations l10n,
  NewFoxerSpace space,
) {
  TourStep welcome() => TourStep(
        icon: Icons.waving_hand_outlined,
        title: l10n.tourWelcomeTitle,
        body: l10n.tourWelcomeBody,
      );
  final firstSteps = TourStep(
    icon: Icons.checklist_rounded,
    title: l10n.tourFirstStepsTitle,
    body: l10n.tourFirstStepsBody,
  );
  final calendar = TourStep(
    icon: Icons.calendar_month_outlined,
    title: l10n.tourCalendarTitle,
    body: l10n.tourCalendarBody,
  );
  final earnings = TourStep(
    icon: Icons.account_balance_wallet_outlined,
    title: l10n.tourEarningsTitle,
    body: l10n.tourEarningsBody,
  );
  final more = TourStep(
    icon: Icons.menu_rounded,
    title: l10n.tourMoreTitle,
    body: l10n.tourMoreBody,
  );
  final overview = TourStep(
    icon: Icons.dashboard_outlined,
    title: l10n.tourOverviewTitle,
    body: l10n.tourOverviewBody,
  );

  // Every space has the same five tabs: Overview, its own listings, Calendar,
  // Earnings and More.
  final listings = switch (space) {
    NewFoxerSpace.venue => TourStep(
        icon: Icons.storefront_outlined,
        title: l10n.tourVenuesTitle,
        body: l10n.tourVenuesBody,
      ),
    NewFoxerSpace.event => TourStep(
        icon: Icons.celebration_outlined,
        title: l10n.tourEventsTitle,
        body: l10n.tourEventsBody,
      ),
    NewFoxerSpace.gear => TourStep(
        icon: Icons.inventory_2_outlined,
        title: l10n.tourGearTitle,
        body: l10n.tourGearBody,
      ),
    NewFoxerSpace.services => TourStep(
        icon: Icons.inventory_2_outlined,
        title: l10n.tourListingsTitle,
        body: l10n.tourListingsBody,
      ),
  };
  return [
    [welcome(), overview, firstSteps],
    [listings],
    [calendar],
    [earnings],
    [more],
  ];
}

/// Plays the whole tour of [space] again, every tab in order, from a More
/// screen.
Future<void> replaySpaceTour(
  BuildContext context,
  AppLocalizations l10n,
  NewFoxerSpace space,
) =>
    showSpaceTour(context, [...spaceTourSteps(l10n, space).expand((s) => s)]);
