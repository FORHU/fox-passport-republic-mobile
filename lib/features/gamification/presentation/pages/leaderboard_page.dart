import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/citizens_view.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/foxers_view.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A circular back button with a hairline border.
class _RoundBack extends StatelessWidget {
  const _RoundBack();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The leaderboards: Citizens and Foxers, one switch apart. It opens on
/// [initialSide], and on [initialRole] when that is the Foxers side.
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({
    required this.initialSide,
    required this.initialRole,
    super.key,
  });

  final LeaderboardSide initialSide;

  /// The Foxer role the Foxers side opens on: the one of the space it was
  /// opened from.
  final LeaderboardRole initialRole;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late LeaderboardSide _side = widget.initialSide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        centerTitle: false,
        titleSpacing: 4,
        leadingWidth: 64,
        leading: const _RoundBack(),
        title: Text(
          l10n.leaderboardTitle,
          style: AppTypography.display(size: 26),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedPills<LeaderboardSide>(
              options: [
                SegmentOption(
                  LeaderboardSide.citizens,
                  l10n.leaderboardSideCitizens,
                ),
                SegmentOption(
                  LeaderboardSide.foxers,
                  l10n.leaderboardSideFoxers,
                ),
              ],
              value: _side,
              prominent: true,
              onChanged: (side) => setState(() => _side = side),
            ),
          ),
          Expanded(
            child: _side == LeaderboardSide.citizens
                ? const CitizensView()
                : FoxersView(initialRole: widget.initialRole),
          ),
        ],
      ),
    );
  }
}
