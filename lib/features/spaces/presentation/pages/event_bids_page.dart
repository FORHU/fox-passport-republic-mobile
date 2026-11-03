import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/bids_repository.dart';
import 'package:flutter_template/features/spaces/domain/bid.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The Foxers who applied to supply one event, with a way to accept or turn
/// each down. Only the event's owner or an Organizer is let in by the API.
class EventBidsPage extends ConsumerWidget {
  const EventBidsPage({required this.event, super.key});

  final TeamTarget event;

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    Bid bid, {
    required bool accept,
  }) async {
    final l10n = context.l10n;
    final repo = ref.read(bidsRepositoryProvider);
    try {
      await (accept ? repo.accept(bid) : repo.reject(bid));
      ref.invalidate(bidsProvider(event.id));
      if (context.mounted) {
        showTopToast(
          context,
          accept ? l10n.bidAccepted : l10n.bidRejected,
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.bidActionFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final async = ref.watch(bidsProvider(event.id));

    String price(Bid b) =>
        money.format(b.price, b.currency ?? kBaseCurrency, locale: locale);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        title: Text(event.name, style: AppTypography.display(size: 18)),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(bidsProvider(event.id)),
        ),
        data: (bids) => bids.isEmpty
            ? AppStateView(
                title: l10n.bidsEmpty,
                message: l10n.bidsEmptyBody,
                icon: Icons.how_to_reg_outlined,
              )
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: () => ref.refresh(bidsProvider(event.id).future),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: bids.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final b = bids[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.provider,
                                  style: AppTypography.display(size: 15),
                                ),
                              ),
                              Text(
                                price(b),
                                style: AppTypography.display(size: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.quantity == null
                                ? b.offer
                                : '${b.offer} × ${b.quantity}',
                            style: AppTypography.body(),
                          ),
                          if (b.slot != null)
                            Text(
                              l10n.bidFor(b.slot!),
                              style: AppTypography.label(),
                            ),
                          if (b.message != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              b.message!,
                              style: AppTypography.body(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (b.status == BidStatus.pending)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _answer(
                                      context,
                                      ref,
                                      b,
                                      accept: false,
                                    ),
                                    child: Text(l10n.bidReject),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _answer(
                                      context,
                                      ref,
                                      b,
                                      accept: true,
                                    ),
                                    child: Text(l10n.bidAccept),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              switch (b.status) {
                                BidStatus.accepted => l10n.bidStatusAccepted,
                                BidStatus.rejected => l10n.bidStatusRejected,
                                _ => l10n.bidStatusWithdrawn,
                              },
                              style: AppTypography.label(
                                color: b.status == BidStatus.accepted
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                              ),
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
