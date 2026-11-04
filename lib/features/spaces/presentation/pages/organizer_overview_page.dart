import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/appointment_models.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/featured_photo_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/overview_header.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_home_widgets.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// What the person is called in a team, as a word.
String organizerRoleLabel(AppLocalizations l10n, TeamKind kind) =>
    kind == TeamKind.organizer
        ? l10n.organizerRoleOrganizer
        : l10n.organizerRoleHelper;

/// Accepts or declines an invitation and refreshes the lists it feeds.
Future<void> answerInvitation(
  BuildContext context,
  WidgetRef ref,
  MyAppointment invitation, {
  required bool accept,
}) async {
  final message = context.l10n.organizerAnswerFailed;
  try {
    await ref
        .read(spacesRepositoryProvider)
        .answerAppointment(invitation.id, accept: accept);
    ref.invalidate(myAppointmentsProvider);
  } on Object {
    if (context.mounted) showTopToast(context, message);
  }
}

/// The Organizer space's first screen: what needs an answer (invitations to
/// help run a venue or event), what is coming up next, and the teams the
/// person is on.
class OrganizerOverviewPage extends ConsumerWidget {
  const OrganizerOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final appointments = ref.watch(myAppointmentsProvider);

    final all = appointments.asData?.value ?? const <MyAppointment>[];
    final invitations = [
      for (final a in all)
        if (a.state == AppointmentState.invited) a,
    ];
    final teams = [
      for (final a in all)
        if (a.state == AppointmentState.active) a,
    ];
    final now = DateTime.now();
    // The event you organize that starts next.
    final next = [
      for (final a in teams)
        if (a.isOrganizer && a.startAt != null && !a.startAt!.isBefore(now)) a,
    ]..sort((a, b) => a.startAt!.compareTo(b.startAt!));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.spaceTabOverview),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(myAppointmentsProvider);
          try {
            await ref.read(myAppointmentsProvider.future);
          } on Object {
            // The page shows its own state for what did not load.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const OverviewGreeting(),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.go(RouteNames.spaceOrganizerCalendar),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(l10n.spaceTabCalendar),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => unawaited(
                      context.push(RouteNames.spaceOrganizerInvitations),
                    ),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(l10n.organizerInvitations),
                  ),
                ),
              ],
            ),
            HomeSectionHeader(title: l10n.overviewAttention),
            if (appointments.hasError)
              AttentionRow(
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                text: l10n.apiLoadFailed,
                onTap: () => ref.invalidate(myAppointmentsProvider),
              )
            else if (appointments.hasValue && invitations.isEmpty)
              AllClearCard(text: l10n.overviewAllClear),
            for (final invitation in invitations.take(3)) ...[
              InvitationCard(
                invitation: invitation,
                onAccept: () => unawaited(
                  answerInvitation(context, ref, invitation, accept: true),
                ),
                onDecline: () => unawaited(
                  answerInvitation(context, ref, invitation, accept: false),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (invitations.length > 3)
              AttentionRow(
                icon: Icons.mail_outline_rounded,
                color: AppColors.warning,
                text: l10n.organizerInvitations,
                onTap: () => context.push(RouteNames.spaceOrganizerInvitations),
              ),
            HomeSectionHeader(title: l10n.organizerNextUp),
            if (next.isEmpty)
              Text(
                l10n.organizerNothingNext,
                style: AppTypography.body(color: AppColors.textMuted),
              )
            else
              FeaturedPhotoCard(
                dayLabel: DateFormat.MMMd(locale)
                    .format(next.first.startAt!)
                    .toUpperCase(),
                title: next.first.name,
                subtitle: next.first.place,
                statusChip: _RoleChip(l10n.organizerYouOrganize),
              ),
            HomeSectionHeader(
              title: l10n.organizerOrganizing,
              action: teams.length > 2 ? l10n.venueViewAll : null,
              onAction: () => context.push(RouteNames.spaceTeamEvents),
            ),
            if (appointments.hasValue && teams.isEmpty)
              Text(
                l10n.organizerNoTeams,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            for (final team in teams.take(2)) ...[
              FeaturedPhotoCard(
                dayLabel: organizerRoleLabel(l10n, team.kind).toUpperCase(),
                title: team.name,
                subtitle: team.startAt != null
                    ? DateFormat.MMMd(locale).format(team.startAt!)
                    : team.place,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.roleOrganizer),
      ),
      child: Text(
        label,
        style: AppTypography.label(color: AppColors.roleOrganizer),
      ),
    );
  }
}

/// An invitation to help run a venue or event, with Accept and Decline.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final MyAppointment invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final by = invitation.appointedBy;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            invitation.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(),
          ),
          const SizedBox(height: 2),
          Text(
            [
              organizerRoleLabel(l10n, invitation.kind),
              if (by != null) l10n.organizerInvitedBy(by),
            ].join(' · '),
            style: AppTypography.body(size: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  child: Text(l10n.requestAccept),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: Text(l10n.requestDecline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
