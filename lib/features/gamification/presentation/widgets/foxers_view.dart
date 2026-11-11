import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/leaderboard_labels.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The Foxer board for one role and tab (Top rated, Most booked, Rising) and,
/// optionally, one city. Shows position, name, role and the star rating, never
/// the number of bookings. The caller's own place is pinned below the list when
/// it is further down than the list goes.
class FoxersView extends ConsumerStatefulWidget {
  const FoxersView({required this.initialRole, super.key});

  /// The role the board opens on: the one of the space it was opened from.
  final LeaderboardRole initialRole;

  @override
  ConsumerState<FoxersView> createState() => _FoxersViewState();
}

class _FoxersViewState extends ConsumerState<FoxersView> {
  late LeaderboardRole _role = widget.initialRole;
  FoxerTab _tab = FoxerTab.topRated;
  String? _city;

  BoardQuery get _query => BoardQuery(_role, tab: _tab, city: _city);

  Future<void> _pickCity() async {
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _CitySheet(initial: _city ?? ''),
    );
    if (next == null || !mounted) return;
    setState(() => _city = next.trim().isEmpty ? null : next.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = ref.watch(foxerBoardProvider(_query));
    final myId = ref.watch(currentUserIdProvider);

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final role in LeaderboardRole.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BoardChip(
                    label: roleLabel(l10n, role),
                    selected: role == _role,
                    onTap: () => setState(() => _role = role),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tab in FoxerTab.values)
                BoardChip(
                  label: foxerTabLabel(l10n, tab),
                  selected: tab == _tab,
                  onTap: () => setState(() => _tab = tab),
                ),
            ],
          ),
        ),
        // The board in words, "Manila · Venues · Top rated"; tapping it
        // changes the city.
        InkWell(
          onTap: _pickCity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      _city ?? l10n.leaderboardAllCities,
                      roleLabel(l10n, _role),
                      foxerTabLabel(l10n, _tab),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
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
              onAction: () => ref.invalidate(foxerBoardProvider(_query)),
            ),
            data: (data) => data.rows.isEmpty
                ? AppStateView(
                    kind: AppStateKind.empty,
                    title: l10n.leaderboardEmpty,
                  )
                : BoardList(
                    rows: [for (final e in data.rows) _row(l10n, e, myId)],
                    pinned: data.me != null && !data.meIsListed
                        ? _row(l10n, data.me!, myId)
                        : null,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, FoxerBoardEntry e, String? myId) =>
      BoardRow(
        position: e.position,
        name: e.name,
        image: e.image,
        rolePill: rolePillLabel(l10n, e.role),
        squareAvatar: true,
        isMe: myId != null && e.userId == myId,
        trailing: _Rating(entry: e),
      );
}

/// A Foxer's star rating and review count, or "New" while there are too few
/// reviews for a number to mean anything.
class _Rating extends StatelessWidget {
  const _Rating({required this.entry});

  final FoxerBoardEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!entry.hasRating) {
      return Text(
        l10n.leaderboardFoxerNew,
        style: AppTypography.body(size: 12, color: AppColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 2),
            Text(
              entry.starRating.toStringAsFixed(1),
              style: AppTypography.display(size: 14),
            ),
          ],
        ),
        Text(
          l10n.leaderboardReviews(entry.reviewCount),
          style: AppTypography.body(size: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CitySheet extends StatefulWidget {
  const _CitySheet({required this.initial});

  final String initial;

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l10n.leaderboardCityLabel),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: Text(l10n.leaderboardAllCities),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_controller.text),
                child: Text(l10n.leaderboardCityApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
