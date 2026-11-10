import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// What every space screen has at the right of its top bar: the Coins balance,
/// which opens the Wallet, and the person's photo, which opens Settings (the
/// way to Profile and Sign out, which a space has no tab for). With
/// [showSwitcher] the space the person is in comes first and opens the
/// switcher (Citizen or another role's space); only More turns it on, where
/// switching lives.
class SpaceTopActions extends ConsumerWidget {
  const SpaceTopActions({this.showSwitcher = false, super.key});

  final bool showSwitcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final name = user?.name ?? '';
    final spaces = ref.watch(availableSpacesProvider);
    final active = ref.watch(activeSpaceProvider);
    final roles = ref.watch(heldRolesProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSwitcher && spaces.length > 1)
          Tooltip(
            message: context.l10n.spaceSwitchTitle,
            child: TextButton(
              onPressed: () => unawaited(showSpaceSheet(context)),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: AppColors.textPrimary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active.icon, size: 18, color: spaceColor(active)),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Text(
                      spaceLabel(context.l10n, active, roles: roles),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded, size: 18),
                ],
              ),
            ),
          ),
        // Nothing until the balance is known; the same balance in every space.
        CoinsChip(path: active.xpPath(const []), trailingGap: 4),
        IconButton(
          tooltip: context.l10n.settingsTitle,
          onPressed: () => context.push(RouteNames.settings),
          icon: AvatarImage(
            url: user?.imageUrl,
            radius: 14,
            fallback: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: AppTypography.display(size: 12, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// The top bar of a space's screens: the title, the Coins and the photo, and
/// the space switcher on More ([showSwitcher]).
class SpaceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SpaceAppBar({
    required this.title,
    this.showSwitcher = false,
    super.key,
  });

  final String title;
  final bool showSwitcher;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // The title sits at the left, in line with the content below it, so the
    // bar has no empty stretch there.
    return AppBar(
      centerTitle: false,
      titleSpacing: 16,
      title: Text(title, style: AppTypography.display(size: 18)),
      actions: [SpaceTopActions(showSwitcher: showSwitcher)],
    );
  }
}
