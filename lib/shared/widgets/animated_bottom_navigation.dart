import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/effects.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:gap/gap.dart';

/// A single destination in [AnimatedBottomNavigation].
class NavBarItem {
  const NavBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.showBadge = false,
    this.badgeLabel,
    this.avatarInitial,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Shows a small notification dot on the icon.
  final bool showBadge;
  final String? badgeLabel;

  /// When set, the destination is drawn as a small avatar chip with this
  /// letter instead of an icon (the Passport tab: the person's initial).
  final String? avatarInitial;
}

/// The floating bottom bar: a rounded dark bar, the active destination in the
/// accent colour, a count badge where there is something waiting, and the
/// person's initial for their Passport.
class AnimatedBottomNavigation extends StatelessWidget {
  const AnimatedBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.ui.surface,
            borderRadius: AppRadius.brPill,
            border: Border.all(color: AppColors.ui.borderHairline),
            boxShadow: AppEffects.surfaceShadow,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const active = AppColors.accent;
    final muted = AppColors.text.tertiary;
    final color = selected ? active : muted;
    final initial = item.avatarInitial;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // As wide as the icon, so a badge hangs off the icon's corner
                // and not the edge of the whole cell.
                SizedBox(
                  width: initial == null ? 28 : 48,
                  height: 28,
                  child: Center(
                    child: initial == null
                        ? Icon(
                            selected ? item.activeIcon : item.icon,
                            size: 24,
                            color: color,
                          )
                        : _AvatarChip(initial: initial, selected: selected),
                  ),
                ),
                if (item.showBadge || item.badgeLabel != null)
                  Positioned(
                    right: item.badgeLabel == null ? -2 : -9,
                    top: item.badgeLabel == null ? -1 : -6,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: item.badgeLabel == null ? 9 : 17,
                        minHeight: item.badgeLabel == null ? 9 : 17,
                      ),
                      padding: item.badgeLabel == null
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: AppRadius.brPill,
                        border: Border.all(
                          color: AppColors.ui.surface,
                          width: 1.5,
                        ),
                      ),
                      child: item.badgeLabel == null
                          ? null
                          : Text(
                              item.badgeLabel!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onAccent,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
            const Gap(4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pill holding a filled circle with the person's initial.
class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.initial, required this.selected});

  final String initial;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.borderStrong,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.lightSurface,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.onLightSurface,
            height: 1,
          ),
        ),
      ),
    );
  }
}
