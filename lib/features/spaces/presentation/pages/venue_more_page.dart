import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// The Venue space's More tab: the things that are not a tab of their own.
class VenueMorePage extends ConsumerWidget {
  const VenueMorePage({super.key});

  Future<void> _openWeb(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp('/creator-dashboard');
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final waiting = ref
            .watch(venueRequestsProvider)
            .asData
            ?.value
            .where(
              (r) => r.needsReply,
            )
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.moreTitle, style: AppTypography.display(size: 18)),
        actions: const [SpaceTopActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _MoreRow(
            icon: Icons.inbox_outlined,
            title: l10n.requestsTitle,
            badge: waiting == 0 ? null : '$waiting',
            onTap: () => context.push(RouteNames.spaceVenueRequests),
          ),
          const SizedBox(height: 8),
          _MoreRow(
            icon: Icons.qr_code_scanner_rounded,
            title: l10n.spaceTabCheckIn,
            onTap: () => context.push(RouteNames.spaceVenueCheckIn),
          ),
          const SizedBox(height: 8),
          _MoreRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.messages,
            onTap: () => context.push(RouteNames.spaceVenueMessages),
          ),
          const SizedBox(height: 24),
          _MoreRow(
            icon: Icons.swap_horiz_rounded,
            title: l10n.spaceSwitchTitle,
            onTap: () => showSpaceSheet(context),
          ),
          const SizedBox(height: 8),
          _MoreRow(
            icon: Icons.settings_outlined,
            title: l10n.settingsTitle,
            onTap: () => context.push(RouteNames.settings),
          ),
          const SizedBox(height: 8),
          _MoreRow(
            icon: Icons.open_in_new_rounded,
            title: l10n.spaceManageOnWeb,
            onTap: () => _openWeb(context),
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTypography.display(size: 15)),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  badge!,
                  style: AppTypography.label(color: AppColors.onAccent),
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
