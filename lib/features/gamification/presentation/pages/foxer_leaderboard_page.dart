import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// The Foxer leaderboard: who completed the most bookings this month, for one
/// role and, optionally, one city. Shows position, name and rank, never the
/// number of bookings. The caller's own place is pinned below the list when it
/// is further down than the list goes.
class FoxerLeaderboardPage extends ConsumerStatefulWidget {
  const FoxerLeaderboardPage({required this.initialRole, super.key});

  /// The role the board opens on: the one of the space it was opened from.
  final LeaderboardRole initialRole;

  @override
  ConsumerState<FoxerLeaderboardPage> createState() =>
      _FoxerLeaderboardPageState();
}

class _FoxerLeaderboardPageState extends ConsumerState<FoxerLeaderboardPage> {
  late LeaderboardRole _role = widget.initialRole;
  String? _city;

  BoardQuery get _query => BoardQuery(_role, city: _city);

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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          l10n.leaderboardTitle,
          style: AppTypography.display(size: 22),
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickCity,
            icon: const Icon(Icons.place_outlined, size: 18),
            label: Text(
              _city ?? l10n.leaderboardAllCities,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      body: Column(
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
                    child: ChoiceChip(
                      label: Text(roleLabel(l10n, role)),
                      selected: role == _role,
                      onSelected: (_) => setState(() => _role = role),
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
                  l10n.leaderboardMostBooked,
                  monthLabel(
                    board.value?.month,
                    Localizations.localeOf(context),
                  ),
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
                onAction: () => ref.invalidate(foxerBoardProvider(_query)),
              ),
              data: (data) => data.rows.isEmpty
                  ? AppStateView(
                      kind: AppStateKind.empty,
                      title: l10n.leaderboardEmpty,
                    )
                  : _Board(board: data),
            ),
          ),
        ],
      ),
    );
  }
}

/// The label for a role chip and a row.
String roleLabel(AppLocalizations l10n, LeaderboardRole role) => switch (role) {
      LeaderboardRole.venue => l10n.leaderboardRoleVenue,
      LeaderboardRole.event => l10n.leaderboardRoleEvent,
      LeaderboardRole.gear => l10n.leaderboardRoleGear,
      LeaderboardRole.services => l10n.leaderboardRoleServices,
      LeaderboardRole.performers => l10n.leaderboardRolePerformers,
    };

/// "2026-11" as "November 2026"; empty when there is no month yet or it does
/// not parse.
String monthLabel(String? month, Locale locale) {
  if (month == null || month.isEmpty) return '';
  final parts = month.split('-');
  if (parts.length != 2) return '';
  final year = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (year == null || m == null || m < 1 || m > 12) return '';
  return DateFormat.yMMMM(locale.toString()).format(DateTime(year, m));
}

class _Board extends StatelessWidget {
  const _Board({required this.board});

  final FoxerBoard board;

  @override
  Widget build(BuildContext context) {
    final me = board.me;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: board.rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _Row(entry: board.rows[i]),
          ),
        ),
        // Their own place, when the list does not reach it.
        if (me != null && !board.meIsListed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _Row(entry: me),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final FoxerBoardEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final initial =
        entry.name.trim().isEmpty ? '?' : entry.name.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: entry.isMe ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${entry.position}',
              style: AppTypography.display(
                color: entry.position <= 3
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
          ),
          AvatarImage(
            url: entry.image,
            radius: 20,
            fallback: Text(initial, style: AppTypography.display()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
                Text(
                  l10n.leaderboardRowSubtitle(
                    roleLabel(l10n, entry.role),
                    entry.rankName,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (entry.isMe)
            Text(
              l10n.leaderboardYou,
              style: AppTypography.display(size: 13, color: AppColors.accent),
            ),
        ],
      ),
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
