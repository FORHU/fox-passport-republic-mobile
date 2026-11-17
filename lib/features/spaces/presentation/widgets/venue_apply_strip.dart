import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// For an Event Foxer looking at a venue: apply to host events there, or, once
/// they have, where that stands. Nothing for anyone else.
class VenueApplyStrip extends ConsumerWidget {
  const VenueApplyStrip({
    required this.venueId,
    required this.venueName,
    super.key,
  });

  final String venueId;
  final String venueName;

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.partnersApplyConfirmTitle(venueName)),
        content: Text(l10n.partnersApplyConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.messageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.partnersApplyAction),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final sent = l10n.partnersApplySent;
    final failed = l10n.partnersActionFailed;
    try {
      await ref.read(spacesRepositoryProvider).applyToVenue(venueId);
      ref.invalidate(partnersProvider);
      if (context.mounted) showTopToast(context, sent);
    } on Object {
      if (context.mounted) showTopToast(context, failed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(heldRolesProvider).contains('eventFoxer')) {
      return const SizedBox.shrink();
    }
    final lists = ref.watch(partnersProvider).asData?.value;
    // Not shown until it is known whether they have already applied.
    if (lists == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    Partner? existing;
    for (final p in lists.asEventFoxer) {
      if (p.venueId == venueId) existing = p;
    }

    final status = existing == null
        ? null
        : switch (existing.status) {
            PartnerStatus.pending => existing.startedByEventFoxer
                ? l10n.partnersYouApplied(venueName)
                : l10n.partnersInvitedYou(venueName),
            PartnerStatus.approved => l10n.venueHostingHere,
            PartnerStatus.rejected => l10n.partnersStatusRejected,
            PartnerStatus.revoked => l10n.partnersStatusRevoked,
          };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: status != null
          ? Row(
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    style: AppTypography.body(size: 13),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => unawaited(_apply(context, ref)),
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: Text(l10n.venueApplyToHost),
              ),
            ),
    );
  }
}
