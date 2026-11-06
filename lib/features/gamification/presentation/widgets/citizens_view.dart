import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_template/features/gamification/presentation/leaderboard_labels.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The citizen board: this month, all time, or this month in the caller's own
/// city. Shows position, name, rank and level, never XP. The caller's own place
/// is pinned below the list when it is further down than the list goes.
class CitizensView extends ConsumerStatefulWidget {
  const CitizensView({super.key});

  @override
  ConsumerState<CitizensView> createState() => _CitizensViewState();
}

class _CitizensViewState extends ConsumerState<CitizensView> {
  CitizenTab _tab = CitizenTab.month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = ref.watch(citizenBoardProvider(_tab));

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final tab in CitizenTab.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(citizenTabLabel(l10n, tab)),
                    selected: tab == _tab,
                    onSelected: (_) => setState(() => _tab = tab),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              [
                monthLabel(
                  board.value?.month,
                  Localizations.localeOf(context),
                ),
                if (_tab == CitizenTab.city) board.value?.city ?? '',
              ].where((s) => s.isNotEmpty).join(' · '),
              style: AppTypography.body(size: 13, color: AppColors.textMuted),
            ),
          ),
        ),
        Expanded(
          child: board.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (_, __) => AppStateView(
              kind: AppStateKind.error,
              title: l10n.apiLoadFailed,
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(citizenBoardProvider(_tab)),
            ),
            data: (data) {
              // Without a city of their own there is no city to rank within.
              if (_tab == CitizenTab.city && data.city == null) {
                return AppStateView(
                  title: l10n.leaderboardNoCity,
                  actionLabel: l10n.leaderboardEditProfile,
                  onAction: () => context.push(RouteNames.profileEdit),
                );
              }
              if (data.rows.isEmpty) {
                return AppStateView(
                  kind: AppStateKind.empty,
                  title: l10n.leaderboardEmpty,
                );
              }
              return BoardList(
                rows: [for (final e in data.rows) _row(l10n, e)],
                pinned: data.me != null && !data.meIsListed
                    ? _row(l10n, data.me!)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, CitizenBoardEntry e) => BoardRow(
        position: e.position,
        name: e.name,
        image: e.image,
        subtitle: l10n.rewardsRankLevel(e.rankName, e.level),
        isMe: e.isMe,
      );
}
