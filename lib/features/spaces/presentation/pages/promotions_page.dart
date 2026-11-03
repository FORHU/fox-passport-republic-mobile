import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/promotions_repository.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/promotion.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/promotion_sheet.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The discounts a Foxer offers on their venues: turn one on or off, remove
/// it, or add another.
class PromotionsPage extends ConsumerWidget {
  const PromotionsPage({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action, {
    String? success,
  }) async {
    final failed = context.l10n.promotionActionFailed;
    try {
      await action();
      ref.invalidate(promotionsProvider);
      if (success != null && context.mounted) showTopToast(context, success);
    } on Object {
      if (context.mounted) showTopToast(context, failed);
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final repo = ref.read(promotionsRepositoryProvider);
    try {
      final venues = await ref.read(myVenuesProvider.future);
      if (!context.mounted) return;
      if (venues.isEmpty) {
        showTopToast(context, l10n.promotionNoVenue);
        return;
      }
      final draft = await showPromotionSheet(context, venues);
      if (draft == null || !context.mounted) return;
      await _run(
        context,
        ref,
        () => repo.create(draft),
        success: l10n.promotionCreated,
      );
    } on Object {
      if (context.mounted) showTopToast(context, l10n.promotionActionFailed);
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Promotion promo,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(promotionsRepositoryProvider);
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.promotionDeleteTitle(promo.name)),
        content: Text(l10n.promotionDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.messageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.promotionDelete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => repo.remove(promo.id),
      success: l10n.promotionDeleted,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final async = ref.watch(promotionsProvider);

    String discount(Promotion p) => p.isPercentage
        ? l10n.promotionPercentOff('${p.value}')
        : l10n.promotionAmountOff(
            money.format(p.value, kBaseCurrency, locale: locale),
          );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.promotionsTitle, style: AppTypography.display()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.promotionNew),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          title: l10n.promotionsLoadFailed,
          kind: AppStateKind.error,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(promotionsProvider),
        ),
        data: (promos) => promos.isEmpty
            ? AppStateView(
                title: l10n.promotionsEmpty,
                message: l10n.promotionsEmptyBody,
                icon: Icons.local_offer_outlined,
              )
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () => ref.refresh(promotionsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = promos[i];
                    return Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: AppTypography.body()),
                                Text(
                                  p.autoApply
                                      ? '${discount(p)} · ${l10n.promotionAuto}'
                                      : discount(p),
                                  style: AppTypography.label(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: p.active,
                            onChanged: (on) => _run(
                              context,
                              ref,
                              () => ref
                                  .read(promotionsRepositoryProvider)
                                  .setActive(p.id, active: on),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.promotionDelete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _remove(context, ref, p),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
