import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/match_request_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Passport: your profile, as others see it, under a top bar that holds the
/// things only you have: the space switcher, Saved posts and Settings. The
/// profile itself is passed in by the route, so this feature does not reach
/// into Profile. It is given your [PassportSummary] once that has loaded, for
/// your real level and XP.
class PassportPage extends ConsumerWidget {
  const PassportPage({required this.bodyBuilder, super.key});

  final Widget Function(BuildContext context, PassportSummary? summary)
      bodyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(passportProvider).value;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.passportTitle,
                      style: AppTypography.display(size: 28),
                    ),
                  ),
                  // Only for someone who holds a role to switch to.
                  const SpaceSwitchButton(
                    compact: true,
                    padding: EdgeInsets.only(right: 4),
                  ),
                  // Saved is a screen of its own: everything saved, newest
                  // first, with the posts to like, comment on and share.
                  IconButton(
                    tooltip: l10n.passportTabSaved,
                    onPressed: () =>
                        context.push<void>(RouteNames.republicSaved).ignore(),
                    icon: const Icon(Icons.bookmark_border_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.settingsTitle,
                    onPressed: () => context.push(RouteNames.settings),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: bodyBuilder(context, summary)),
          ],
        ),
      ),
    );
  }
}

/// Your XP and what the next level takes, in one line: `4530 XP · Level 5 at
/// 4993`.
String passportXpText(AppLocalizations l10n, PassportSummary summary) =>
    '${l10n.passportXp(summary.totalXp)} · '
    '${l10n.passportNextLevel(summary.level + 1, summary.nextLevelXp)}';

/// The people you have asked to match with, and where each stands. A tab on
/// your own profile.
class PassportMatchesTab extends ConsumerWidget {
  const PassportMatchesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(myMatchRequestsProvider);

    return requests.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (_, __) => AppStateView(
        kind: AppStateKind.error,
        title: l10n.apiLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(myMatchRequestsProvider),
      ),
      data: (list) {
        final shown = list.where((r) => !r.needsPayment).toList();
        if (shown.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                l10n.ticketsEmptyRequests,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final MatchRequestItem r in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MatchRequestCard(item: r),
              ),
          ],
        );
      },
    );
  }
}

/// How to apply for a Foxer role. A tab on your own profile.
class PassportEarnTab extends StatelessWidget {
  const PassportEarnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.passportEarnIntro, style: AppTypography.body()),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push(RouteNames.roles),
            child: Text(l10n.passportEarnApply),
          ),
        ),
      ],
    );
  }
}
