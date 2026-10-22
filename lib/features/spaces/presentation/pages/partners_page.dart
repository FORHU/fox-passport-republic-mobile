import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/catalog_picker_sheet.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The venue partnerships of one side: for a Mayor, the Event Foxers who
/// applied or were invited; for an Event Foxer, the venues they can run events
/// at. Whoever did not start a partnership is the one who answers it.
class PartnersPage extends ConsumerWidget {
  const PartnersPage({required this.side, super.key});

  final PartnerSide side;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success,
  ) async {
    final failed = context.l10n.partnersActionFailed;
    try {
      await action();
      ref.invalidate(partnersProvider);
      if (context.mounted) showTopToast(context, success);
    } on Object {
      if (context.mounted) showTopToast(context, failed);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String yes,
  }) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.messageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(yes, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return sure ?? false;
  }

  /// A Mayor invites an Event Foxer to host at one of their live venues: the
  /// venue first (when there is a choice), then the Foxer.
  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final repo = ref.read(spacesRepositoryProvider);
    List<SpaceListing> mine;
    try {
      mine = await ref.read(myVenuesProvider.future);
    } on Object {
      if (context.mounted) showTopToast(context, l10n.partnersActionFailed);
      return;
    }
    final live = [
      for (final v in mine)
        if (v.status == 'available') v,
    ];
    if (!context.mounted) return;
    if (live.isEmpty) {
      showTopToast(context, l10n.partnersInviteNoVenue);
      return;
    }
    final venue =
        live.length == 1 ? live.first : await _chooseVenue(context, live);
    if (venue == null || !context.mounted) return;

    // Whoever already has a partnership at this venue cannot be asked again.
    final taken = {
      for (final p in ref.read(partnersProvider).asData?.value.asMayor ??
          const <Partner>[])
        if (p.venueId == venue.id) p.partnerId,
    };
    final foxer = await pickCatalogItem(
      context,
      kind: CatalogKind.foxers,
      title: l10n.partnersInviteTitle,
      hint: l10n.partnersInviteHint,
      empty: l10n.partnersInviteNone,
      taken: taken,
      where: (item) => item.roles.contains('eventFoxer'),
    );
    if (foxer == null || !context.mounted) return;
    final sure = await _confirm(
      context,
      title: l10n.partnersInviteConfirmTitle(foxer.title),
      body: l10n.partnersInviteConfirmBody(venue.name),
      yes: l10n.partnersInviteAction,
    );
    if (!sure || !context.mounted) return;
    await _run(
      context,
      ref,
      () => repo.inviteEventFoxer(venue.id, foxer.id),
      l10n.partnersInviteSent,
    );
  }

  Future<SpaceListing?> _chooseVenue(
    BuildContext context,
    List<SpaceListing> venues,
  ) {
    return showModalBottomSheet<SpaceListing>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l10n.partnersChooseVenue,
              style: AppTypography.display(size: 18),
            ),
            const SizedBox(height: 8),
            for (final v in venues)
              ListTile(
                title: Text(v.name),
                subtitle: v.city == null ? null : Text(v.city!),
                onTap: () => Navigator.of(sheet).pop(v),
              ),
          ],
        ),
      ),
    );
  }

  /// Picks a venue and applies to host events there. A venue already on the
  /// list, in any state, cannot be applied to again.
  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final taken = {
      for (final p in ref.read(partnersProvider).asData?.value.asEventFoxer ??
          const <Partner>[])
        p.venueId,
    };
    final venue = await pickCatalogItem(
      context,
      kind: CatalogKind.venues,
      title: l10n.partnersApplyTitle,
      hint: l10n.partnersSearchHint,
      empty: l10n.partnersApplyNone,
      taken: taken,
    );
    if (venue == null || !context.mounted) return;
    final sure = await _confirm(
      context,
      title: l10n.partnersApplyConfirmTitle(venue.title),
      body: l10n.partnersApplyConfirmBody,
      yes: l10n.partnersApplyAction,
    );
    if (!sure || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(spacesRepositoryProvider).applyToVenue(venue.id),
      l10n.partnersApplySent,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final lists = ref.watch(partnersProvider);
    final repo = ref.read(spacesRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => side == PartnerSide.eventFoxer
            ? _apply(context, ref)
            : _invite(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          side == PartnerSide.eventFoxer
              ? l10n.partnersApply
              : l10n.partnersInvite,
        ),
      ),
      appBar: AppBar(
        title: Text(
          l10n.partnersTitle,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      body: lists.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(partnersProvider),
        ),
        data: (all) {
          final items = all.forSide(side);
          final needsAnswer = [
            for (final p in items)
              if (p.awaitingMe) p,
          ];
          final waiting = [
            for (final p in items)
              if (p.startedByMe) p,
          ];
          final active = [
            for (final p in items)
              if (p.status == PartnerStatus.approved) p,
          ];
          final past = [
            for (final p in items)
              if (p.status == PartnerStatus.rejected ||
                  p.status == PartnerStatus.revoked)
                p,
          ];

          Widget section(String title, List<Partner> rows) => rows.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                      child: Text(
                        title,
                        style: AppTypography.display(size: 15),
                      ),
                    ),
                    for (final p in rows) ...[
                      PartnerCard(
                        partner: p,
                        onApprove: () => _run(
                          context,
                          ref,
                          () => repo.approvePartner(p.id),
                          l10n.partnersApproved,
                        ),
                        onReject: () async {
                          final sure = await _confirm(
                            context,
                            title: l10n.partnersRejectTitle,
                            body: l10n.partnersRejectBody,
                            yes: side == PartnerSide.mayor
                                ? l10n.partnersReject
                                : l10n.partnersDecline,
                          );
                          if (!sure || !context.mounted) return;
                          await _run(
                            context,
                            ref,
                            () => repo.rejectPartner(p.id),
                            l10n.partnersRejected,
                          );
                        },
                        onWithdraw: () => _run(
                          context,
                          ref,
                          () => repo.cancelPartner(p.id),
                          l10n.partnersWithdrawn,
                        ),
                        onRevoke: () async {
                          final sure = await _confirm(
                            context,
                            title: l10n.partnersRevokeTitle,
                            body: l10n.partnersRevokeBody(
                              p.partnerName,
                              p.venueName,
                            ),
                            yes: l10n.partnersRevoke,
                          );
                          if (!sure || !context.mounted) return;
                          await _run(
                            context,
                            ref,
                            () => repo.revokePartner(p.id),
                            l10n.partnersRevoked,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.refresh(partnersProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                // Room under the last card for the button.
                96,
              ),
              children: [
                Text(
                  side == PartnerSide.mayor
                      ? l10n.partnersIntroMayor
                      : l10n.partnersIntroEvent,
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      l10n.partnersEmpty,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                  ),
                section(l10n.partnersNeedsAnswer, needsAnswer),
                section(l10n.partnersWaitingForThem, waiting),
                section(l10n.partnersActive, active),
                section(l10n.partnersPast, past),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _headline(AppLocalizations l10n, Partner p) {
  final mayor = p.side == PartnerSide.mayor;
  if (p.status == PartnerStatus.approved) {
    return l10n.partnersActiveAt(
      mayor ? p.partnerName : l10n.partnersTitle,
      p.venueName,
    );
  }
  if (mayor) {
    return p.startedByEventFoxer
        ? l10n.partnersApplied(p.partnerName, p.venueName)
        : l10n.partnersYouInvited(p.partnerName, p.venueName);
  }
  return p.startedByEventFoxer
      ? l10n.partnersYouApplied(p.venueName)
      : l10n.partnersInvitedYou(p.venueName);
}

/// One partnership and what the person can do with it.
class PartnerCard extends ConsumerWidget {
  const PartnerCard({
    required this.partner,
    required this.onApprove,
    required this.onReject,
    required this.onWithdraw,
    required this.onRevoke,
    super.key,
  });

  final Partner partner;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onWithdraw;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = partner;
    final mayor = p.side == PartnerSide.mayor;
    final money = ref.watch(moneyFormatterProvider);
    final locale = Localizations.localeOf(context).toString();
    final price = p.agreedPrice;

    String? note;
    if (p.status == PartnerStatus.rejected) note = l10n.partnersStatusRejected;
    if (p.status == PartnerStatus.revoked) note = l10n.partnersStatusRevoked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: p.awaitingMe ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhotoBox(
                url: mayor ? p.partnerImageUrl : p.venueImageUrl,
                width: 48,
                height: 48,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _headline(l10n, p),
                  style: AppTypography.body(),
                ),
              ),
            ],
          ),
          if (price != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.partnersAgreedPrice(
                money.format(price, kBaseCurrency, locale: locale),
              ),
              style: AppTypography.label(color: AppColors.textSecondary),
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: AppTypography.label(),
            ),
          ],
          if (p.awaitingMe) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: Text(
                      mayor ? l10n.partnersApprove : l10n.partnersAccept,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: Text(
                      mayor ? l10n.partnersReject : l10n.partnersDecline,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (p.startedByMe) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onWithdraw,
              child: Text(l10n.partnersWithdraw),
            ),
          ] else if (p.canRevoke) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRevoke,
              child: Text(
                l10n.partnersRevoke,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
