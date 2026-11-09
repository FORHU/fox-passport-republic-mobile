import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One row of a space's More tab: an icon, a name, an optional count, and a
/// chevron. [compact] drops the chevron and the height, for two to a row.
class MoreRow extends StatelessWidget {
  const MoreRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 52 : 56),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: compact ? 20 : 22, color: AppColors.textMuted),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(size: compact ? 14 : 15),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  badge!,
                  style: AppTypography.label(color: AppColors.onAccent),
                ),
              ),
            if (!compact)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
