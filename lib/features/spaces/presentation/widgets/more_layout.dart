import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A small heading over a group of a space's More tab ("Grow", "You").
class MoreSectionLabel extends StatelessWidget {
  const MoreSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label(color: AppColors.textSecondary),
      ),
    );
  }
}

/// A big tap target for what is used most: an icon over a name, with an
/// optional count in the corner. Three of them sit side by side at the top of
/// More, so those screens are one tap away.
class MoreQuickTile extends StatelessWidget {
  const MoreQuickTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 26, color: AppColors.accent),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.display(size: 13),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: -4,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.label(color: AppColors.onAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays children out two to a row with an even gap, so a group of short
/// entries takes half the height of a list. A last odd one spans the row.
class MoreGrid extends StatelessWidget {
  const MoreGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      // A lone last entry takes the whole row, so there is no empty slot.
      rows.add(
        i + 1 < children.length
            ? Row(
                children: [
                  Expanded(child: children[i]),
                  const SizedBox(width: 8),
                  Expanded(child: children[i + 1]),
                ],
              )
            : children[i],
      );
    }
    return Column(children: rows);
  }
}
