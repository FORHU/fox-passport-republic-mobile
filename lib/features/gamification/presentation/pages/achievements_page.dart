import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/achievements_repository.dart';
import 'package:flutter_template/features/gamification/domain/achievements.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/achievement_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/pill_chip.dart';
import 'package:flutter_template/shared/widgets/round_back_button.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The account roles that run something on the platform, whose Foxer
/// achievements are worth showing.
const _foxerRoles = {
  'venueFoxer',
  'eventFoxer',
  'providerFoxer',
};

/// Every achievement with its tiers and progress, and how many tiers are
/// earned out of how many there are. In progress, Done and Locked filter the
/// list; Foxer achievements show only for someone who holds a Foxer role.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  AchievementState _filter = AchievementState.inProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(achievementsProvider);
    final withFoxer = ref.watch(
      authControllerProvider.select(
        (s) => (s.user?.roleType ?? const []).any(_foxerRoles.contains),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        centerTitle: false,
        titleSpacing: 4,
        leadingWidth: 64,
        leading: const RoundBackButton(),
        title: Text(
          l10n.achievementsTitle,
          style: AppTypography.display(size: 26),
        ),
      ),
      body: summary.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(achievementsProvider),
        ),
        data: (data) => _Loaded(
          summary: data,
          withFoxer: withFoxer,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.summary,
    required this.withFoxer,
    required this.filter,
    required this.onFilter,
  });

  final AchievementsSummary summary;
  final bool withFoxer;
  final AchievementState filter;
  final ValueChanged<AchievementState> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = [
      for (final a in summary.visible(withFoxer: withFoxer))
        if (a.state == filter) a,
    ];
    final citizen = [
      for (final a in shown)
        if (!a.isFoxer) a,
    ];
    final foxer = [
      for (final a in shown)
        if (a.isFoxer) a,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _Summary(
          earned: summary.earned(withFoxer: withFoxer),
          total: summary.totalTiers(withFoxer: withFoxer),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final state in _filters)
              PillChip(
                label: _label(l10n, state),
                selected: state == filter,
                onTap: () => onFilter(state),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              _empty(l10n, filter),
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          )
        else ...[
          if (citizen.isNotEmpty) ...[
            if (withFoxer) _SectionTitle(l10n.achievementsSectionCitizen),
            for (final a in citizen) _spaced(AchievementCard(achievement: a)),
          ],
          if (foxer.isNotEmpty) ...[
            _SectionTitle(l10n.achievementsSectionFoxer),
            for (final a in foxer) _spaced(AchievementCard(achievement: a)),
          ],
        ],
      ],
    );
  }

  /// The filters, in the order they are shown.
  static const List<AchievementState> _filters = [
    AchievementState.inProgress,
    AchievementState.done,
    AchievementState.locked,
  ];

  static String _label(AppLocalizations l10n, AchievementState s) =>
      switch (s) {
        AchievementState.inProgress => l10n.achievementsFilterProgress,
        AchievementState.done => l10n.achievementsFilterDone,
        AchievementState.locked => l10n.achievementsFilterLocked,
      };

  static String _empty(AppLocalizations l10n, AchievementState s) =>
      switch (s) {
        AchievementState.inProgress => l10n.achievementsEmptyProgress,
        AchievementState.done => l10n.achievementsEmptyDone,
        AchievementState.locked => l10n.achievementsEmptyLocked,
      };

  static Widget _spaced(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: child,
      );
}

/// "12 of 38 earned" over a progress bar.
class _Summary extends StatelessWidget {
  const _Summary({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.achievementsOf(earned, total),
                style: AppTypography.display(size: 24),
              ),
              const Spacer(),
              Text(
                l10n.achievementsEarned,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (earned / total).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(AppColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label(),
      ),
    );
  }
}
