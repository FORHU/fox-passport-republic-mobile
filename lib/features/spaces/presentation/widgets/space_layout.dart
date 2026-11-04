import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/new_foxer.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour_content.dart';
import 'package:flutter_template/shared/widgets/animated_bottom_navigation.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shell of a space (Venue or Event): its screens, one navigator each, and
/// its own bottom bar. The order of [items] is the order of the shell's
/// branches in `app_routes.dart`.
class SpaceLayout extends ConsumerStatefulWidget {
  const SpaceLayout({
    required this.navigationShell,
    required this.items,
    this.tourSpace,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<NavBarItem> items;

  /// The space whose first-time tour runs on each tab the first time a new
  /// Foxer opens it; null for no tour.
  final NewFoxerSpace? tourSpace;

  static String? _badge(int count) =>
      count == 0 ? null : (count > 99 ? '99+' : '$count');

  /// The Venue space: Overview, Venues, Calendar, Earnings and More.
  /// [waiting] is how many requests need a reply, shown on Overview;
  /// [partnersWaiting] is how many partnerships do, shown on More.
  static List<NavBarItem> venueItems(
    BuildContext context, {
    int waiting = 0,
    int partnersWaiting = 0,
  }) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabOverview,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        badgeLabel: _badge(waiting),
      ),
      NavBarItem(
        label: l10n.spaceTabVenues,
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabCalendar,
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabEarnings,
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabMore,
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu_rounded,
        badgeLabel: _badge(partnersWaiting),
      ),
    ];
  }

  /// The Event space, the same five as the others: Overview, Events,
  /// Calendar, Earnings and More. [partnersWaiting] is how many venue
  /// partnerships need an answer, shown on More.
  static List<NavBarItem> eventItems(
    BuildContext context, {
    int partnersWaiting = 0,
  }) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabOverview,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabEvents,
        icon: Icons.celebration_outlined,
        activeIcon: Icons.celebration_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabCalendar,
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabEarnings,
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabMore,
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu_rounded,
        badgeLabel: _badge(partnersWaiting),
      ),
    ];
  }

  /// The Organizer space: Overview, Calendar, Check-in, Messages and More.
  /// [invitations] is how many invitations wait for an answer, shown on
  /// Overview.
  static List<NavBarItem> organizerItems(
    BuildContext context, {
    int invitations = 0,
  }) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabOverview,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        badgeLabel: _badge(invitations),
      ),
      NavBarItem(
        label: l10n.spaceTabCalendar,
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabCheckIn,
        icon: Icons.qr_code_scanner_rounded,
        activeIcon: Icons.qr_code_scanner_rounded,
      ),
      NavBarItem(
        label: l10n.messages,
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabMore,
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu_rounded,
      ),
    ];
  }

  /// A provider's space: Overview, [listings] (Gear, Services or
  /// Performances), Calendar, Earnings and More. [waiting] is how many
  /// requests need a reply, shown on Overview.
  static List<NavBarItem> providerItems(
    BuildContext context, {
    required String listings,
    int waiting = 0,
  }) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabOverview,
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        badgeLabel: _badge(waiting),
      ),
      NavBarItem(
        label: listings,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabCalendar,
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabEarnings,
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabMore,
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu_rounded,
      ),
    ];
  }

  @override
  ConsumerState<SpaceLayout> createState() => _SpaceLayoutState();
}

class _SpaceLayoutState extends ConsumerState<SpaceLayout> {
  /// Tabs already looked at in this session, so a tour is offered once.
  final _visited = <int>{};

  /// How many times the tour had been asked for again when last looked.
  int _restarts = 0;

  @override
  void initState() {
    super.initState();
    _restarts = ref.read(tourRestartProvider);
    _offerTour();
  }

  @override
  void didUpdateWidget(SpaceLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _offerTour();
  }

  /// Shows the tour of the tab now open, once: it is remembered per account
  /// and tab, and comes back only when the Foxer asks for it.
  void _offerTour() {
    final space = widget.tourSpace;
    final tab = widget.navigationShell.currentIndex;
    if (space == null) return;
    final restarts = ref.read(tourRestartProvider);
    if (restarts != _restarts) {
      _restarts = restarts;
      _visited.clear();
    }
    if (!_visited.add(tab)) return;
    unawaited(_runTour(space, tab));
  }

  Future<void> _runTour(NewFoxerSpace space, int tab) async {
    final SharedPreferences prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } on Object {
      return;
    }
    final key = tourSeenKey(ref.read(currentUserIdProvider), space, tab);
    if (prefs.getBool(key) ?? false) return;
    // Let the screen load what it shows, so the tour can point at it.
    await ref.read(newFoxerProvider(space).future);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    // Another tab may have been opened while this was loading.
    if (widget.navigationShell.currentIndex != tab) {
      _visited.remove(tab);
      return;
    }
    final steps = spaceTourSteps(context.l10n, space);
    if (tab >= steps.length) return;
    await prefs.setBool(key, true);
    if (!mounted) return;
    await showSpaceTour(context, steps[tab]);
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final items = widget.items;
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: navigationShell,
      bottomNavigationBar: AnimatedBottomNavigation(
        items: items,
        currentIndex: currentIndex,
        itemKeys: [for (var i = 0; i < items.length; i++) TourKeys.tab(i)],
        // Tapping the tab you are on goes back to its first screen.
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        ),
      ),
    );
  }
}
