import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// "Challenges", a row that opens the booking challenges. For the citizen
/// Passport, under the Milestones row.
class ChallengesRow extends StatelessWidget {
  const ChallengesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push(RouteNames.challenges),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.bolt_outlined,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.challengesTitle,
                  style: AppTypography.display(size: 14),
                ),
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
