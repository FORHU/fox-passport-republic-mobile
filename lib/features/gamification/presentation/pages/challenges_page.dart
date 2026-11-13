import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:flutter_template/features/gamification/presentation/pages/milestones_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The booking challenges: short goals that start over every day, week and
/// month, each with how far along it is. Read-only; the server counts. A
/// challenge shows what it pays only once an amount is set.
class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(milestonesProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: milestonesAppBar(context, title: l10n.challengesTitle),
      body: summary.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(milestonesProvider),
        ),
        data: (data) => data.challenges.isEmpty
            ? AppStateView(
                kind: AppStateKind.empty,
                title: l10n.challengesEmpty,
              )
            : _Loaded(challenges: data.challenges),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.challenges});

  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.challengesBookingSection.toUpperCase(),
            style: AppTypography.label(),
          ),
        ),
        for (final c in challenges)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChallengeCard(challenge: c),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Text(
            l10n.challengesPendingNote,
            style: AppTypography.body(size: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

String _periodLabel(AppLocalizations l10n, ChallengePeriod p) => switch (p) {
      ChallengePeriod.day => l10n.challengesPeriodDay,
      ChallengePeriod.week => l10n.challengesPeriodWeek,
      ChallengePeriod.month => l10n.challengesPeriodMonth,
    };

/// One challenge: its name, "Week · 1 of 3 bookings", a progress bar, and on
/// the right what it pays (or "Done").
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = challenge;
    return Semantics(
      container: true,
      label: l10n.challengesOpen(c.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(minHeight: 64),
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
                  Text(c.name, style: AppTypography.display(size: 14)),
                  const SizedBox(height: 2),
                  Text(
                    l10n.challengesProgress(
                      _periodLabel(l10n, c.period),
                      c.currentCount.clamp(0, c.target),
                      c.target,
                    ),
                    style: AppTypography.body(
                      size: 12,
                    ),
                  ),
                  if (c.currentCount > 0 || c.isCompleted) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: AppRadius.brPill,
                      child: LinearProgressIndicator(
                        value: c.isCompleted ? 1 : c.progress,
                        minHeight: 4,
                        color: AppColors.accent,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (c.isCompleted) ...[
              const SizedBox(width: 12),
              Text(
                l10n.challengesDone.toUpperCase(),
                style: AppTypography.label(color: AppColors.success),
              ),
            ] else if (c.tokens > 0) ...[
              const SizedBox(width: 12),
              _Reward(tokens: c.tokens),
            ],
          ],
        ),
      ),
    );
  }
}

/// "+20" over "Tokens", at the end of a card.
class _Reward extends StatelessWidget {
  const _Reward({required this.tokens});

  final int tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('+$tokens', style: AppTypography.display(size: 13)),
        Text(
          context.l10n.rewardsCoins,
          style: AppTypography.body(size: 12),
        ),
      ],
    );
  }
}
