import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The perks a host or Mayor offers: what each costs, how many were bought and
/// how many are left, with Take down, and a button to add another.
class OfferedPerksPage extends ConsumerWidget {
  const OfferedPerksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offered = ref.watch(offeredPerksProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.perksYours, style: AppTypography.display(size: 20)),
      ),
      body: offered.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(offeredPerksProvider),
        ),
        data: (list) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(offeredPerksProvider);
            await ref.read(offeredPerksProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              PrimaryButton(
                label: l10n.perksAdd,
                icon: Icons.add_rounded,
                onPressed: () => unawaited(context.push(RouteNames.perkNew)),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    l10n.perksOfferedEmpty,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                )
              else
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OfferedCard(offered: p),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferedCard extends ConsumerStatefulWidget {
  const _OfferedCard({required this.offered});

  final OfferedPerk offered;

  @override
  ConsumerState<_OfferedCard> createState() => _OfferedCardState();
}

class _OfferedCardState extends ConsumerState<_OfferedCard> {
  bool _busy = false;

  Future<void> _takeDown() async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.perksTakeDownTitle),
        content: Text(l10n.perksTakeDownBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.perkCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.perksTakeDown),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(perksRepositoryProvider).takeDown(widget.offered.perk.id);
      ref
        ..invalidate(offeredPerksProvider)
        ..invalidate(perksProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(context, l10n.perksTakenDown);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(
        context,
        e is AppException && e.message.isNotEmpty
            ? e.message
            : l10n.perksTakeDownFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final o = widget.offered;
    final left = o.perk.remaining;

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
            children: [
              Expanded(
                child: Text(
                  o.perk.title,
                  style: AppTypography.display(
                    color:
                        o.active ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              const Icon(coinsIcon, size: 16),
              const SizedBox(width: 4),
              Text(
                format.format(o.perk.tokenCost),
                style: AppTypography.display(size: 15),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              l10n.perksBought(o.redeemed),
              if (left != null) l10n.perksLeft(left),
              if (!o.active) l10n.perksOff,
            ].join(' · '),
            style: AppTypography.body(size: 12, color: AppColors.textMuted),
          ),
          if (o.active) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.perksTakeDown,
              isLoading: _busy,
              onPressed: _busy ? null : _takeDown,
            ),
          ],
        ],
      ),
    );
  }
}
