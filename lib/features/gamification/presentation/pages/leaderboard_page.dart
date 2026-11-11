import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/foxers_view.dart';
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

/// The Foxer leaderboard, the only leaderboard. It opens on [initialRole]: the
/// one of the space it was opened from.
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({required this.initialRole, super.key});

  final LeaderboardRole initialRole;

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
      body: FoxersView(initialRole: initialRole),
    );
  }
}
