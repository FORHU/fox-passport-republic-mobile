import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The name of a space, as the person reads it.
String spaceLabel(AppLocalizations l10n, AppSpace space) => switch (space) {
      AppSpace.citizen => l10n.spaceCitizen,
      AppSpace.venue => l10n.spaceVenue,
      AppSpace.event => l10n.spaceEvent,
    };

String spaceHint(AppLocalizations l10n, AppSpace space) => switch (space) {
      AppSpace.citizen => l10n.spaceCitizenHint,
      AppSpace.venue => l10n.spaceVenueHint,
      AppSpace.event => l10n.spaceEventHint,
    };

/// Lets someone who holds a role choose where to work: Citizen, or the Venue
/// or Event space their role opens. Switching opens that space.
Future<void> showSpaceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // Sized to its content, not to a fixed share of the screen.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => const _SpaceSheet(),
  );
}

class _SpaceSheet extends ConsumerWidget {
  const _SpaceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spaces = ref.watch(availableSpacesProvider);
    final active = ref.watch(activeSpaceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.spaceSwitchTitle, style: AppTypography.display(size: 18)),
          const SizedBox(height: 4),
          Text(l10n.spaceSwitchHint, style: AppTypography.body(size: 13)),
          const SizedBox(height: 16),
          for (final space in spaces) ...[
            _SpaceRow(
              space: space,
              selected: space == active,
              onTap: () async {
                final router = GoRouter.of(context);
                final navigator = Navigator.of(context);
                await ref.read(activeSpaceProvider.notifier).select(space);
                navigator.pop();
                router.go(space.root);
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({
    required this.space,
    required this.selected,
    required this.onTap,
  });

  final AppSpace space;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              space.icon,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spaceLabel(l10n, space),
                    style: AppTypography.display(size: 15),
                  ),
                  Text(
                    spaceHint(l10n, space),
                    style: AppTypography.body(size: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

/// A small "Venue ▾" button for a screen's top bar that opens the switcher.
/// Draws nothing for someone with no role to switch to.
class SpaceSwitchButton extends ConsumerWidget {
  const SpaceSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(availableSpacesProvider);
    if (spaces.length < 2) return const SizedBox.shrink();
    final l10n = context.l10n;
    final active = ref.watch(activeSpaceProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: () => unawaited(showSpaceSheet(context)),
        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
        label: Text(spaceLabel(l10n, active)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          // The theme makes buttons full width; an app bar cannot hold that.
          minimumSize: const Size(0, 40),
        ),
      ),
    );
  }
}
