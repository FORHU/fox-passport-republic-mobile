import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_realtime.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/notifications/data/notifications_realtime.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/widgets/animated_bottom_navigation.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// App shell: hosts the tabs (one navigator each) and the bottom navigation.
///
/// ADD or REMOVE tabs by editing `_destinations` — no other changes needed.
class MainLayout extends ConsumerWidget {
  const MainLayout({required this.navigationShell, super.key});

  /// The tabs, each with its own navigator, and which one is showing.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live updates for chats and the bell for as long as the shell is up.
    ref
      ..watch(messagesRealtimeProvider)
      ..watch(notificationsRealtimeProvider);

    // ── Tab definitions ────────────────────────────────────────────────────
    // Each entry pairs a [NavBarItem] with its root route. The active tab is
    // resolved by matching the current location against `route`.
    //
    // TO CUSTOMIZE: replace the placeholder entries below with your own
    // feature pages. Keep `RouteNames.*` in sync with `route_names.dart`.
    final destinations = <_Destination>[
      _Destination(
        item: NavBarItem(
          label: context.l10n.home,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        route: RouteNames.home,
      ),
      _Destination(
        item: NavBarItem(
          label: context.l10n.search,
          icon: Icons.search_rounded,
          activeIcon: Icons.search_rounded,
        ),
        route: RouteNames.search,
      ),
      _Destination(
        item: NavBarItem(
          label: context.l10n.bookings,
          icon: Icons.event_available_outlined,
          activeIcon: Icons.event_available_rounded,
          badgeLabel: _countLabel(ref.watch(needsYouCountProvider)),
        ),
        route: RouteNames.tickets,
      ),
      _Destination(
        item: NavBarItem(
          label: context.l10n.calendar,
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month_rounded,
        ),
        route: RouteNames.calendar,
      ),
      _Destination(
        item: NavBarItem(
          label: context.l10n.messages,
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          badgeLabel: _unreadLabel(ref),
        ),
        route: RouteNames.messages,
      ),
      _Destination(
        item: NavBarItem(
          label: context.l10n.passport,
          icon: Icons.badge_outlined,
          activeIcon: Icons.badge_rounded,
          avatarInitial: _initial(
            ref.watch(authControllerProvider.select((s) => s.user?.name)),
          ),
          avatarImageUrl: ref.watch(
            authControllerProvider.select((s) => s.user?.imageUrl),
          ),
        ),
        route: RouteNames.passport,
      ),
    ];

    assert(
      listEquals(
        [for (final d in destinations) d.route],
        RouteNames.shellTabs,
      ),
      'Tab bar order must match RouteNames.shellTabs (the shell branch order).',
    );

    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.ui.background,
      body: navigationShell,
      bottomNavigationBar: AnimatedBottomNavigation(
        items: [for (final d in destinations) d.item],
        currentIndex: currentIndex,
        // Tapping the tab you are on goes back to its first screen.
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        ),
      ),
    );
  }

  /// The first letter of the person's name, for the Passport tab.
  static String? _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed.substring(0, 1).toUpperCase();
  }

  static String? _countLabel(int count) {
    if (count == 0) return null;
    return count > 99 ? '99+' : '$count';
  }

  static String? _unreadLabel(WidgetRef ref) {
    final items = ref.watch(conversationsProvider).asData?.value;
    final count = items?.fold<int>(
          0,
          (total, conversation) => total + conversation.unreadCount,
        ) ??
        0;
    if (count == 0) return null;
    return count > 99 ? '99+' : '$count';
  }
}

class _Destination {
  const _Destination({required this.item, required this.route});

  final NavBarItem item;
  final String route;
}
