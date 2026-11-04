import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/appointment_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/organizer_overview_page.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Every invitation waiting for an answer.
class OrganizerInvitationsPage extends ConsumerWidget {
  const OrganizerInvitationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appointments = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          l10n.organizerInvitations,
          style: AppTypography.display(size: 18),
        ),
      ),
      body: appointments.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(myAppointmentsProvider),
        ),
        data: (all) {
          final invitations = [
            for (final a in all)
              if (a.state == AppointmentState.invited) a,
          ];
          if (invitations.isEmpty) {
            return Center(
              child: Text(
                l10n.organizerNoInvitations,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: invitations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => InvitationCard(
              invitation: invitations[i],
              onAccept: () => unawaited(
                answerInvitation(context, ref, invitations[i], accept: true),
              ),
              onDecline: () => unawaited(
                answerInvitation(context, ref, invitations[i], accept: false),
              ),
            ),
          );
        },
      ),
    );
  }
}
