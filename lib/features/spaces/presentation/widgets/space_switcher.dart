import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Whether the person lists performances and nothing else, for whom the
/// Services space reads "Performer".
bool _performerOnly(List<String> roles) =>
    roles.contains('performerFoxer') && !roles.contains('serviceFoxer');

/// The name of a space, as the person reads it. [roles] are the roles they
/// hold: a Performer Foxer's Services space is called Performer.
String spaceLabel(
  AppLocalizations l10n,
  AppSpace space, {
  List<String> roles = const [],
}) =>
    switch (space) {
      AppSpace.citizen => l10n.spaceCitizen,
      AppSpace.venue => l10n.spaceVenue,
      AppSpace.event => l10n.spaceEvent,
      AppSpace.gear => l10n.spaceGear,
      AppSpace.services =>
        _performerOnly(roles) ? l10n.spacePerformer : l10n.spaceServices,
    };

String spaceHint(
  AppLocalizations l10n,
  AppSpace space, {
  List<String> roles = const [],
}) =>
    switch (space) {
      AppSpace.citizen => l10n.spaceCitizenHint,
      AppSpace.venue => l10n.spaceVenueHint,
      AppSpace.event => l10n.spaceEventHint,
      AppSpace.gear => l10n.spaceGearHint,
      AppSpace.services => _performerOnly(roles)
          ? l10n.spacePerformerHint
          : l10n.spaceServicesHint,
    };

/// What a provider's Listings tab is called: Gear, Services or Performances.
String listingsLabel(
  AppLocalizations l10n,
  ProviderKind kind, {
  List<String> roles = const [],
}) =>
    kind.isGear
        ? l10n.providerGear
        : (_performerOnly(roles)
            ? l10n.spaceTabPerformances
            : l10n.providerServices);

/// The colour a space is known by: the role's own for the spaces that have
/// one, and a neutral white for Citizen.
Color spaceColor(AppSpace space) => switch (space) {
      AppSpace.citizen => AppColors.textPrimary,
      AppSpace.venue => AppColors.roleVenue,
      AppSpace.event => AppColors.roleEvent,
      AppSpace.gear => AppColors.roleGear,
      AppSpace.services => AppColors.roleTalent,
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
    final roles = ref.watch(heldRolesProvider);
    final active = ref.watch(activeSpaceProvider);
    final user = ref.watch(authControllerProvider).user;
    final name = user?.name ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Who this is, so it is clear that one account holds every space.
          Row(
            children: [
              AvatarImage(
                url: user?.imageUrl,
                radius: 22,
                fallback: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: AppTypography.display(color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? (user?.email ?? '') : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(),
                    ),
                    if (name.isNotEmpty && user != null)
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.spaceWorkingAs.toUpperCase(),
            style: AppTypography.label(),
          ),
          const SizedBox(height: 8),
          for (final space in spaces) ...[
            _SpaceRow(
              space: space,
              roles: roles,
              selected: space == active,
              onTap: () async {
                final router = GoRouter.of(context);
                final navigator = Navigator.of(context);
                final overlay = Overlay.of(context, rootOverlay: true);
                final calm = MediaQuery.disableAnimationsOf(context);
                final switched =
                    l10n.spaceSwitched(spaceLabel(l10n, space, roles: roles));
                navigator.pop();
                if (space == active) return;

                Future<void> change() async {
                  await ref.read(activeSpaceProvider.notifier).select(space);
                  router.go(space.root);
                }

                // The two spaces are different apps, so the old one fades out
                // and the new one fades in rather than one jumping to the
                // other.
                if (calm) {
                  await change();
                } else {
                  await _fadeThrough(overlay, change);
                }
                if (overlay.mounted) {
                  showTopToastIn(
                    overlay,
                    switched,
                    duration: const Duration(seconds: 2),
                  );
                }
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
    required this.roles,
    required this.selected,
    required this.onTap,
  });

  final AppSpace space;
  final List<String> roles;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = spaceColor(space);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    color.withValues(alpha: 0.10),
                    AppColors.surfaceRaised,
                  )
                : AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.7) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // The space's own colour on a soft tile, so each is told apart
              // at a glance.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(space.icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spaceLabel(l10n, space, roles: roles),
                      style: AppTypography.display(size: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spaceHint(l10n, space, roles: roles),
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Text(
                  l10n.spaceCurrent,
                  style: AppTypography.label(color: color),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Covers the screen with the canvas colour, runs [change] behind it, and
/// fades back out.
Future<void> _fadeThrough(
  OverlayState overlay,
  Future<void> Function() change,
) async {
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FadeVeil(
      change: change,
      onDone: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  await done.future;
}

class _FadeVeil extends StatefulWidget {
  const _FadeVeil({required this.change, required this.onDone});

  final Future<void> Function() change;
  final VoidCallback onDone;

  @override
  State<_FadeVeil> createState() => _FadeVeilState();
}

class _FadeVeilState extends State<_FadeVeil>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await _fade.animateTo(
        1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
      await widget.change();
      // A moment for the new space to draw before it is uncovered.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      await _fade.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeIn,
      );
    } on Object {
      // Whatever went wrong, never leave the screen covered.
    } finally {
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Absorbs taps while it is up, so nothing is pressed mid-switch.
    return FadeTransition(
      opacity: _fade,
      child: const ModalBarrier(color: AppColors.canvas, dismissible: false),
    );
  }
}

/// The space the person is in, as a small pill for a screen's top bar. It
/// opens the switcher. Draws nothing for someone with no role to switch to.
class SpaceSwitchButton extends ConsumerWidget {
  const SpaceSwitchButton({
    this.padding = const EdgeInsets.only(right: 8),
    this.compact = false,
    super.key,
  });

  /// Space around the pill.
  final EdgeInsets padding;

  /// Just the space's icon and a chevron, for a row that has no room for its
  /// name.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(availableSpacesProvider);
    if (spaces.length < 2) return const SizedBox.shrink();
    final l10n = context.l10n;
    final active = ref.watch(activeSpaceProvider);
    final roles = ref.watch(heldRolesProvider);
    final color = spaceColor(active);

    return Padding(
      padding: padding,
      child: Material(
        color: AppColors.surface,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.borderStrong),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => unawaited(showSpaceSheet(context)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, maxWidth: 150),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Named for a screen reader, which cannot read an icon alone.
                  Tooltip(
                    message: spaceLabel(l10n, active, roles: roles),
                    child: Icon(active.icon, size: 16, color: color),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        spaceLabel(l10n, active, roles: roles),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(size: 13, color: color),
                      ),
                    ),
                  ],
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
