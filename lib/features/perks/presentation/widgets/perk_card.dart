import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// One perk on the Perks tab: what it is, who offers it, what it costs, and a
/// View button (or how far off it is when the person cannot afford it yet).
class PerkCard extends StatelessWidget {
  const PerkCard({required this.perk, super.key});

  final Perk perk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final remaining = perk.remaining;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(perk.title, style: AppTypography.display()),
              ),
              const SizedBox(width: 8),
              const Icon(coinsIcon, size: 16),
              const SizedBox(width: 4),
              Text(
                format.format(perk.tokenCost),
                style: AppTypography.display(size: 15),
              ),
            ],
          ),
          if (perk.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              perk.description!,
              style: AppTypography.body(size: 13, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  perk.isHost
                      ? l10n.perksOfferedByHost
                      : l10n.perksOfferedByVenue,
                  style: AppTypography.body(
                    size: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(width: 8),
                Text(
                  l10n.perksLeft(remaining),
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (perk.canAfford)
            SecondaryButton(
              label: l10n.perksView,
              onPressed: () =>
                  unawaited(context.push(RouteNames.perkDetail(perk.id))),
            )
          else ...[
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: perk.tokenCost == 0
                    ? 0
                    : ((perk.tokenCost - perk.tokensShort) / perk.tokenCost)
                        .clamp(0, 1)
                        .toDouble(),
                minHeight: 6,
                backgroundColor: AppColors.surfaceRaised,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.rewardsToGo(format.format(perk.tokensShort)),
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
