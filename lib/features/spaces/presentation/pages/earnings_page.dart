import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// What the person has been paid, what is still owed, the latest payouts, and
/// whether their payout account is set up. Setting it up takes bank and
/// identity details, so that part is finished on the web.
class EarningsPage extends ConsumerWidget {
  const EarningsPage({super.key});

  Future<void> _setUp(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp('/creator-dashboard/stripe-onboard');
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final payouts = ref.watch(payoutsProvider);
    final stripe = ref.watch(stripeStatusProvider);

    String format(num amount) =>
        money.format(amount, kBaseCurrency, locale: locale);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          l10n.spaceTabEarnings,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      body: payouts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(payoutsProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref
              ..invalidate(stripeStatusProvider)
              ..invalidate(payoutsProvider);
            try {
              await ref.read(payoutsProvider.future);
            } on Object {
              // The page shows its own error state with a retry.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Total(
                      label: l10n.earningsPending,
                      value: format(summary.totals.pending),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Total(
                      label: l10n.earningsPaid,
                      value: format(summary.totals.paid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SetupCard(
                status: stripe.asData?.value,
                onSetUp: () => _setUp(context),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.earningsRecent.toUpperCase(),
                style: AppTypography.label(),
              ),
              const SizedBox(height: 10),
              if (summary.rows.isEmpty)
                Text(
                  l10n.earningsNone,
                  style: AppTypography.body(color: AppColors.textMuted),
                )
              else
                for (final row in summary.rows) ...[
                  _PayoutTile(row: row, locale: locale, format: format),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.body(size: 12)),
        ],
      ),
    );
  }
}

/// Where payout setup stands, and the way to finish it.
class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.status, required this.onSetUp});

  /// Null while it loads or if it could not be read.
  final StripeStatus? status;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = status?.payoutsEnabled ?? false;
    final started = status?.hasAccount ?? false;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: ready ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready
                    ? Icons.check_circle_rounded
                    : Icons.account_balance_outlined,
                color: ready ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ready ? l10n.earningsSetupReady : l10n.earningsSetup,
                  style: AppTypography.display(size: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ready ? l10n.earningsSetupReadyHint : l10n.earningsSetupHint,
            style: AppTypography.body(size: 12),
          ),
          if (!ready) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label:
                  started ? l10n.earningsSetupFinish : l10n.earningsSetupStart,
              icon: Icons.open_in_new_rounded,
              onPressed: onSetUp,
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({
    required this.row,
    required this.locale,
    required this.format,
  });

  final PayoutRow row;
  final String locale;
  final String Function(num) format;

  static String _status(AppLocalizations l10n, String status) =>
      switch (status) {
        'paid' => l10n.payoutPaid,
        'failed' => l10n.payoutFailed,
        _ => l10n.payoutPending,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = switch (row.status) {
      'paid' => AppColors.success,
      'failed' => AppColors.error,
      _ => AppColors.warning,
    };
    final when = row.paidAt ?? row.createdAt;
    return Container(
      padding: const EdgeInsets.all(12),
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
                Text(
                  format(row.amount),
                  style: AppTypography.display(),
                ),
                Text(
                  [
                    if (row.source == 'event_venue_transaction')
                      l10n.payoutSourceVenue
                    else
                      l10n.payoutSourceOther,
                    if (when != null) DateFormat.MMMd(locale).format(when),
                  ].join(' · '),
                  style: AppTypography.body(size: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.brPill,
            ),
            child: Text(
              _status(l10n, row.status),
              style: AppTypography.label(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
