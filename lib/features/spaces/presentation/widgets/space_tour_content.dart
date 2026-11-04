import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// The first-time tour of a space, one list of cards per bottom-bar tab, in
/// the order of the tabs. The dashboard's cards zoom in on the part they
/// describe; each other tab's card points at its place in the bar.
List<List<TourStep>> spaceTourSteps(
  AppLocalizations l10n,
  NewFoxerSpace space,
) {
  TourStep tab(
    int index, {
    required IconData icon,
    required String title,
    required String body,
  }) =>
      TourStep(
        icon: icon,
        title: title,
        body: body,
        target: 'tab-$index',
      );

  final dashboard = [
    TourStep(
      icon: Icons.waving_hand_outlined,
      title: l10n.tourWelcomeTitle,
      body: l10n.tourWelcomeBody,
    ),
    TourStep(
      icon: Icons.bolt_outlined,
      title: l10n.tourActionsTitle,
      body: l10n.tourActionsBody,
      target: 'dash-actions',
    ),
    TourStep(
      icon: Icons.inbox_outlined,
      title: l10n.tourNeedsTitle,
      body: l10n.tourNeedsBody,
      target: 'dash-needs',
    ),
    TourStep(
      icon: Icons.checklist_rounded,
      title: l10n.tourFirstStepsTitle,
      body: l10n.tourFirstStepsBody,
      target: 'dash-steps',
      optional: true,
    ),
    TourStep(
      icon: Icons.account_balance_wallet_outlined,
      title: l10n.tourEarningsCardTitle,
      body: l10n.tourEarningsCardBody,
      target: 'dash-earnings',
      optional: true,
    ),
  ];

  // Every space has the same five tabs: Dashboard, its own listings,
  // Calendar, Earnings and More.
  final listings = switch (space) {
    NewFoxerSpace.venue => tab(
        1,
        icon: Icons.storefront_outlined,
        title: l10n.tourVenuesTitle,
        body: l10n.tourVenuesBody,
      ),
    NewFoxerSpace.event => tab(
        1,
        icon: Icons.celebration_outlined,
        title: l10n.tourEventsTitle,
        body: l10n.tourEventsBody,
      ),
    NewFoxerSpace.gear => tab(
        1,
        icon: Icons.inventory_2_outlined,
        title: l10n.tourGearTitle,
        body: l10n.tourGearBody,
      ),
    NewFoxerSpace.services => tab(
        1,
        icon: Icons.inventory_2_outlined,
        title: l10n.tourListingsTitle,
        body: l10n.tourListingsBody,
      ),
  };
  return [
    dashboard,
    [listings],
    [
      tab(
        2,
        icon: Icons.calendar_month_outlined,
        title: l10n.tourCalendarTitle,
        body: l10n.tourCalendarBody,
      ),
    ],
    [
      tab(
        3,
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.tourEarningsTitle,
        body: l10n.tourEarningsBody,
      ),
    ],
    [
      tab(
        4,
        icon: Icons.menu_rounded,
        title: l10n.tourMoreTitle,
        body: l10n.tourMoreBody,
      ),
    ],
  ];
}

/// Counts every time a Foxer asks for the tour again, so the space shell
/// knows to offer it.
final NotifierProvider<TourRestarts, int> tourRestartProvider =
    NotifierProvider<TourRestarts, int>(TourRestarts.new);

class TourRestarts extends Notifier<int> {
  @override
  int build() => 0;

  void ask() => state++;
}

/// The key a tab's tour is remembered under, per account and device.
String tourSeenKey(String? userId, NewFoxerSpace space, int tab) =>
    'spaceTourSeen.${userId ?? 'anon'}.${space.name}.$tab';

/// Plays the tour of [space] again: forgets that its tabs were seen and opens
/// its dashboard, where the tour starts and carries on tab by tab.
Future<void> restartSpaceTour(
  WidgetRef ref,
  BuildContext context,
  NewFoxerSpace space,
  String dashboard,
) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final userId = ref.read(currentUserIdProvider);
    for (var tab = 0; tab < 5; tab++) {
      await prefs.remove(tourSeenKey(userId, space, tab));
    }
  } on Object {
    // Without saved settings nothing was remembered, so nothing to forget.
  }
  ref.read(tourRestartProvider.notifier).ask();
  if (context.mounted) context.go(dashboard);
}
