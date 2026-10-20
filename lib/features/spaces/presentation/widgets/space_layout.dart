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

  /// The Venue space: Requests, Venues, Check-in, Messages.
  static List<NavBarItem> venueItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabRequests,
        icon: Icons.inbox_outlined,
        activeIcon: Icons.inbox_rounded,
      ),
      NavBarItem(
        label: l10n.spaceTabVenues,
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront_rounded,
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

  /// The Event space: Events, Check-in, Messages.
  static List<NavBarItem> eventItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavBarItem(
        label: l10n.spaceTabEvents,
        icon: Icons.celebration_outlined,
        activeIcon: Icons.celebration_rounded,
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
