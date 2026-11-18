import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/presentation/widgets/perk_card.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The perks the host of an event package offers, for someone booked on it.
class PackagePerksPage extends ConsumerWidget {
  const PackagePerksPage({required this.templateId, super.key});

  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final listing = ref.watch(packagePerksProvider(templateId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          l10n.perkForThisEvent,
          style: AppTypography.display(size: 20),
        ),
      ),
      body: listing.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(packagePerksProvider(templateId)),
        ),
        data: (data) => data.perks.isEmpty
            ? Center(
                child: Text(
                  l10n.perkForEventEmpty,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  for (final perk in data.perks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PerkCard(perk: perk),
                    ),
                ],
              ),
      ),
    );
  }
}
