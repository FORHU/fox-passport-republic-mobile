import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/more_row.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:go_router/go_router.dart';

/// The Organizer space's More tab: the invitations, the switch to another
/// space, settings, and the rest of the creator dashboard on the web.
class OrganizerMorePage extends StatelessWidget {
  const OrganizerMorePage({super.key});

  Future<void> _openWeb(BuildContext context) async {
    final message = context.l10n.onboardingWebNotConfigured;
    final opened = await openWebApp('/creator-dashboard');
    if (!opened && context.mounted) showTopToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.moreTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          MoreRow(
            icon: Icons.mail_outline_rounded,
            title: l10n.organizerInvitations,
            onTap: () => context.push(RouteNames.spaceOrganizerInvitations),
          ),
          const SizedBox(height: 24),
          MoreRow(
            icon: Icons.swap_horiz_rounded,
            title: l10n.spaceSwitchTitle,
            onTap: () => unawaited(showSpaceSheet(context)),
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
