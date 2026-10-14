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
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Shows a small notification dot on the icon.
  final bool showBadge;
  final String? badgeLabel;
}

/// Premium floating glass bottom navigation with a smooth animated active
/// pill. Uses the app design tokens.
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
    final primary = AppColors.ink.primary;
    final muted = AppColors.text.tertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: AppRadius.brPill,
                ),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected ? primary : muted,
                ),
              ),
              if (item.showBadge || item.badgeLabel != null)
                Positioned(
                  right: item.badgeLabel == null ? 6 : -7,
                  top: item.badgeLabel == null ? 0 : -5,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: item.badgeLabel == null ? 9 : 16,
                      minHeight: item.badgeLabel == null ? 9 : 16,
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
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onAccent,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const Gap(4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? primary : muted,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
