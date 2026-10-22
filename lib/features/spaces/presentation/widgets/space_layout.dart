import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/widgets/animated_bottom_navigation.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// The shell of a space (Venue or Event): its screens, one navigator each, and
/// its own bottom bar. The order of [items] is the order of the shell's
/// branches in `app_routes.dart`.
class SpaceLayout extends StatelessWidget {
  const SpaceLayout({
    required this.navigationShell,
    required this.items,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<NavBarItem> items;

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

  /// The Event space: Events, Calendar, Check-in, Messages.
  static List<NavBarItem> eventItems(
    BuildContext context, {
    int partnersWaiting = 0,
  }) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabEvents,
        icon: Icons.celebration_outlined,
        activeIcon: Icons.celebration_rounded,
        badgeLabel: _badge(partnersWaiting),
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: navigationShell,
      bottomNavigationBar: AnimatedBottomNavigation(
        items: items,
        currentIndex: currentIndex,
        // Tapping the tab you are on goes back to its first screen.
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        ),
      ),
    );
  }
}
