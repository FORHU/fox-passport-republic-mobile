import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/more_row.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// The Provider space's More tab: what is not a tab of its own.
class ProviderMorePage extends ConsumerWidget {
  const ProviderMorePage({super.key});

  Future<void> _openWeb(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp('/creator-dashboard');
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final waiting = ref
            .watch(supplyRequestsProvider)
            .asData
            ?.value
            .where((r) => r.needsReply)
            .length ??
        0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.moreTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          MoreRow(
            icon: Icons.inbox_outlined,
            title: l10n.requestsTitle,
            badge: waiting == 0 ? null : '$waiting',
            onTap: () => context.push(RouteNames.spaceProviderRequests),
          ),
          const SizedBox(height: 8),
          MoreRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.messages,
            onTap: () => context.push(RouteNames.spaceProviderMessages),
          ),
          const SizedBox(height: 24),
          MoreRow(
            icon: Icons.swap_horiz_rounded,
            title: l10n.spaceSwitchTitle,
            onTap: () => unawaited(showSpaceSheet(context)),
          ),
          const SizedBox(height: 8),
          MoreRow(
            icon: Icons.settings_outlined,
            title: l10n.settingsTitle,
            onTap: () => context.push(RouteNames.settings),
          ),
          const SizedBox(height: 8),
          MoreRow(
            icon: Icons.open_in_new_rounded,
            title: l10n.spaceManageOnWeb,
            onTap: () => unawaited(_openWeb(context)),
          ),
        ],
      ),
    );
  }
}
