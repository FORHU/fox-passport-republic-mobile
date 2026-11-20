import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The person's perks: ready to use (with a Show code button), used, and
/// expired (with the Tokens that came back).
class MyPerksPage extends ConsumerWidget {
  const MyPerksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final perks = ref.watch(myPerksProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(l10n.perksMine, style: AppTypography.display(size: 20)),
      ),
      body: perks.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(myPerksProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                l10n.perksMineEmpty,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            );
          }
          List<MyPerk> of(MyPerkState s) => [
                for (final p in list)
                  if (p.state == s) p,
              ];
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              ref.invalidate(myPerksProvider);
              await ref.read(myPerksProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Group(l10n.perksSectionReady, of(MyPerkState.ready)),
                _Group(l10n.perksSectionUsed, of(MyPerkState.used)),
                _Group(l10n.perksSectionExpired, of(MyPerkState.expired)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.perks);

  final String title;
  final List<MyPerk> perks;

  @override
  Widget build(BuildContext context) {
    if (perks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title.toUpperCase(), style: AppTypography.label()),
        const SizedBox(height: 8),
        for (final p in perks)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MyPerkCard(perk: p),
          ),
      ],
    );
  }
}

class _MyPerkCard extends StatelessWidget {
  const _MyPerkCard({required this.perk});

  final MyPerk perk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale);
    final format = NumberFormat.decimalPattern(locale);
    final ready = perk.state == MyPerkState.ready;

    final note = switch (perk.state) {
      MyPerkState.ready => perk.expiresAt == null
          ? null
          : l10n.perkUseBy(date.format(perk.expiresAt!)),
      MyPerkState.used =>
        perk.usedAt == null ? null : l10n.perkUsedOn(date.format(perk.usedAt!)),
      MyPerkState.expired => perk.expiresAt == null
          ? null
          : l10n.perkExpiredOn(date.format(perk.expiresAt!)),
    };

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
                  perk.title,
                  style: AppTypography.display(
                    color: ready ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              if (ready)
                Text(
                  l10n.perkReady,
                  style: AppTypography.body(size: 12, color: AppColors.accent),
                ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
          if (perk.state == MyPerkState.expired) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.perkTokensReturned(format.format(perk.tokensSpent)),
                    style:
                        AppTypography.body(size: 13, color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ],
          if (ready) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.perkShowCode,
              onPressed: () =>
                  unawaited(context.push(RouteNames.perkCode(perk.id))),
            ),
          ],
        ],
      ),
    );
  }
}
