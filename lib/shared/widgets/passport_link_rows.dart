import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// "Saved", a row that opens your saved posts. For the citizen Passport, under
/// the other rows.
class SavedRow extends StatelessWidget {
  const SavedRow({super.key});

  @override
  Widget build(BuildContext context) => _LinkRow(
        icon: Icons.bookmark_border_rounded,
        title: context.l10n.republicSaved,
        route: RouteNames.republicSaved,
      );
}

/// "Earn as a Foxer", a row that opens the roles to apply for and where each
/// stands. For the citizen Passport, under the Saved row.
class EarnAsFoxerRow extends StatelessWidget {
  const EarnAsFoxerRow({super.key});

  @override
  Widget build(BuildContext context) => _LinkRow(
        icon: Icons.workspace_premium_outlined,
        title: context.l10n.passportEarnAsFoxerRow,
        route: RouteNames.roles,
      );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTypography.display(size: 14)),
              ),
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
