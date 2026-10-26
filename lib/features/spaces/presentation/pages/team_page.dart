import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The venues (for a Mayor) or upcoming events (for an Event Foxer) the person
/// can build a team for. Tapping one opens its team.
class TeamPage extends ConsumerWidget {
  const TeamPage({required this.events, super.key});

  /// Events when true; otherwise venues.
  final bool events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = events ? teamEventsProvider : teamVenuesProvider;
    final targets = ref.watch(provider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.teamTitle, style: AppTypography.display(size: 18)),
        actions: const [SpaceTopActions()],
      ),
      body: targets.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(provider),
        ),
        data: (rows) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(provider);
            try {
              await ref.read(provider.future);
            } on Object {
              // The page shows its own error state with a retry.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(
                l10n.teamIntro,
                style: AppTypography.body(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
                child: Text(
                  events ? l10n.teamYourEvents : l10n.teamYourVenues,
                  style: AppTypography.display(size: 15),
                ),
              ),
              if (rows.isEmpty)
                Text(
                  events ? l10n.teamNoEvents : l10n.teamNoVenues,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              for (final target in rows) ...[
                _TargetRow(target: target),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.target});

  final TeamTarget target;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: () => context.push(RouteNames.spaceTeamDetail, extra: target),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    target.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 15),
                  ),
                  if (target.detail.isNotEmpty)
                    Text(
                      target.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
