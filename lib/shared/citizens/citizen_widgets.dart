import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The pieces of a person's card, shared by their profile and the Passport so
/// the two look the same.
extension CitizenScale on BuildContext {
  /// 1.0 on a 360 dp phone, smaller on a narrower one and a little larger on
  /// a wide one, so these fit whatever screen they are on.
  double get fit => (MediaQuery.sizeOf(this).width / 360).clamp(0.82, 1.15);
}

/// Captions and chips: the mono label at a smaller size, with less spacing
/// between letters than the default, so they take less room. Follows the
/// screen width.
TextStyle citizenTiny(
  BuildContext context, {
  Color color = AppColors.textMuted,
}) =>
    AppTypography.label(color: color).copyWith(
      fontSize: 9.5 * context.fit,
      letterSpacing: 0.5 * context.fit,
    );

/// How a role is named on a chip: `EVENT FOXER`, and Partner Foxer for an
/// investor.
String citizenRoleLabel(AppLocalizations l10n, String role) =>
    (role == 'investor'
            ? l10n.citizenPartner
            : role.replaceAll('Foxer', ' Foxer'))
        .toUpperCase();

/// Their photo, or their initial, in a rounded square with a ring, and a
/// "Level N" chip on the corner. Gold for a Partner Foxer.
class CitizenAvatar extends StatelessWidget {
  const CitizenAvatar({
    required this.name,
    required this.level,
    this.imageUrl,
    this.partner = false,
    super.key,
  });

  final String name;
  final int level;
  final String? imageUrl;
  final bool partner;

  @override
  Widget build(BuildContext context) {
    final accent = partner ? AppColors.warning : AppColors.accent;
    final size = 64 * context.fit;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent, accent.withValues(alpha: 0.45)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.5),
            child: imageUrl == null || imageUrl!.isEmpty
                ? ColoredBox(
                    color: AppColors.surfaceRaised,
                    child: Center(
                      child: Text(
                        name.isEmpty
                            ? '?'
                            : name.characters.first.toUpperCase(),
                        style: AppTypography.display(
                          size: 24 * context.fit,
                          color: accent,
                        ),
                      ),
                    ),
                  )
                : NetworkImageBox(
                    url: imageUrl!,
                    width: size - 5,
                    height: size - 5,
                  ),
          ),
        ),
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: partner ? AppColors.warning : AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: partner ? AppColors.warning : AppColors.accentTintBorder,
              ),
            ),
            child: Text(
              context.l10n.citizenLevelChip(level),
              style: citizenTiny(
                context,
                color: partner ? AppColors.onAccent : AppColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small tinted label: a role, a specialization or an XP amount.
class CitizenChip extends StatelessWidget {
  const CitizenChip({
    required this.label,
    required this.color,
    this.icon,
    this.soft = false,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool soft;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: soft ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11 * context.fit, color: color),
              const SizedBox(width: 3),
            ],
            Text(label, style: citizenTiny(context, color: color)),
          ],
        ),
      );
}
