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

  return switch (space) {
    NewFoxerSpace.event => [
        [
          welcome(),
          TourStep(
            icon: Icons.celebration_outlined,
            title: l10n.tourEventsTitle,
            body: l10n.tourEventsBody,
          ),
          firstSteps,
        ],
        [calendar],
        [
          TourStep(
            icon: Icons.qr_code_scanner_rounded,
            title: l10n.tourCheckInTitle,
            body: l10n.tourCheckInBody,
          ),
        ],
        [
          TourStep(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.tourMessagesTitle,
            body: l10n.tourMessagesBody,
          ),
        ],
      ],
    _ => [
        [welcome(), overview, firstSteps],
        [
          switch (space) {
            NewFoxerSpace.venue => TourStep(
                icon: Icons.storefront_outlined,
                title: l10n.tourVenuesTitle,
                body: l10n.tourVenuesBody,
              ),
            NewFoxerSpace.gear => TourStep(
                icon: Icons.inventory_2_outlined,
                title: l10n.tourGearTitle,
                body: l10n.tourGearBody,
              ),
            _ => TourStep(
                icon: Icons.inventory_2_outlined,
                title: l10n.tourListingsTitle,
                body: l10n.tourListingsBody,
              ),
          },
        ],
        [calendar],
        [earnings],
        [more],
      ],
  };
}

/// Plays the whole tour of [space] again, every tab in order, from a More
/// screen.
Future<void> replaySpaceTour(
  BuildContext context,
  AppLocalizations l10n,
  NewFoxerSpace space,
) =>
    showSpaceTour(context, [...spaceTourSteps(l10n, space).expand((s) => s)]);
