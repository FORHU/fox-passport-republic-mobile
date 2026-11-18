import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/features/perks/presentation/widgets/perk_card.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The Perks part of Rewards: a link to the person's own perks (with how many
/// are ready), then the perks on offer. Loading, failing and empty each have
/// their own look.
class PerksSection extends ConsumerWidget {
  const PerksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final listing = ref.watch(perksProvider);
    final mine = ref.watch(myPerksProvider).asData?.value;
    final ready = mine?.where((p) => p.state == MyPerkState.ready).length ?? 0;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => unawaited(context.push(RouteNames.perksMine)),
            child: Text(
              ready > 0 ? l10n.perksMineReady(ready) : l10n.perksMine,
              style: AppTypography.body(
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        listing.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          error: (_, __) => AppStateView(
            kind: AppStateKind.error,
            title: l10n.apiLoadFailed,
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(perksProvider),
          ),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.held > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.perksHeldNote(format.format(data.held)),
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              if (data.perks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      l10n.perksEmpty,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                for (final perk in data.perks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PerkCard(perk: perk),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
