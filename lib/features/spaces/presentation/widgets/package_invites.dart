import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/package_invites_repository.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/controllers/package_invite_controller.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Package invites for a Provider (mobile#491), from the canvas "Package
/// requests inbox", "Request to join a package" and "Decline: reasons".

String inviteReasonLabel(AppLocalizations l10n, InviteDeclineReason r) =>
    switch (r) {
      InviteDeclineReason.unavailableOnDate => l10n.inviteReasonUnavailable,
      InviteDeclineReason.priceTooLow => l10n.inviteReasonPrice,
      InviteDeclineReason.notMyKindOfEvent => l10n.inviteReasonKind,
      InviteDeclineReason.tooFar => l10n.inviteReasonFar,
      InviteDeclineReason.noCapacity => l10n.inviteReasonCapacity,
      InviteDeclineReason.other => l10n.inviteReasonOther,
    };

String? _price(BuildContext context, WidgetRef ref, PackageInvite invite) {
  final price = invite.price;
  if (price == null) return null;
  final locale = Localizations.localeOf(context).toString();
  return ref
      .watch(moneyFormatterProvider)
      .format(price, invite.currency ?? kBaseCurrency, locale: locale);
}

/// Pending invites first, then the packages already joined, for one kind of
/// listing: a space shows only its own (venues, gear or services).
class PackageInvitesView extends ConsumerWidget {
  const PackageInvitesView({required this.kind, super.key});

  final RequestKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final empty = switch (kind) {
      RequestKind.venue => l10n.invitesEmptyVenue,
      RequestKind.asset => l10n.invitesEmptyGear,
      RequestKind.service => l10n.invitesEmptyServices,
    };
    return ref.watch(packageInvitesProvider).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          error: (_, __) => AppStateView(
            kind: AppStateKind.error,
            title: l10n.apiLoadFailed,
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(packageInvitesProvider),
          ),
          data: (all) {
            final mine = all.where((i) => i.isFor(kind));
            final pending =
                mine.where((i) => i.status == InviteStatus.pending).toList();
            final joined =
                mine.where((i) => i.status == InviteStatus.accepted).toList();
            if (pending.isEmpty && joined.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  empty,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final invite in pending) ...[
                  _PendingCard(invite: invite),
                  const SizedBox(height: 12),
                ],
                if (joined.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.invitesInPackages.toUpperCase(),
                    style: AppTypography.label(),
                  ),
                  const SizedBox(height: 10),
                  for (final invite in joined) ...[
                    _JoinedRow(invite: invite),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            );
          },
        );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.invite});

  final PackageInvite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final price = _price(context, ref, invite);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(invite.packageName, style: AppTypography.display()),
          const SizedBox(height: 6),
          Text(
            [
              if (invite.hostName != null) invite.hostName!,
              invite.itemName,
              if (price != null) l10n.invitePerEvent(price),
            ].join(' · '),
            style: AppTypography.body(size: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PackageInvitePage(invite: invite),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              ),
              child: Text(
                l10n.inviteReview,
                style:
                    AppTypography.display(size: 15, color: AppColors.onAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinedRow extends ConsumerWidget {
  const _JoinedRow({required this.invite});

  final PackageInvite invite;

  /// Leaves the package, with a reason the Event Foxer sees (api#461).
  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final repo = ref.read(packageInvitesRepositoryProvider);
    final left = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => DeclineReasonSheet(
        title: l10n.inviteLeaveTitle,
        subtitle: '${invite.packageName} · ${invite.itemName}',
        seenBy: l10n.inviteDeclineSeen,
        onDecline: (reason, note) async {
          try {
            await repo.leave(invite, reason: reason, note: note);
            return null;
          } on Object catch (e) {
            return e is AppException ? e.message : '';
          }
        },
      ),
    );
    if (left != true || !context.mounted) return;
    ref.invalidate(packageInvitesProvider);
    showTopToast(context, l10n.inviteLeft(invite.packageName));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.packageName,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  invite.itemName,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _leave(context, ref),
            child: Text(l10n.inviteLeave),
          ),
        ],
      ),
    );
  }
}

/// One invite: what it is, who asked, the price, and Decline or Join.
class PackageInvitePage extends ConsumerWidget {
  const PackageInvitePage({required this.invite, super.key});

  final PackageInvite invite;

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await ref
        .read(packageInviteControllerProvider.notifier)
        .respond(invite, accept: true);
    if (!context.mounted) return;
    if (ok) {
      showTopToast(context, l10n.inviteJoined(invite.packageName));
      Navigator.of(context).pop();
    } else {
      final why = ref.read(packageInviteControllerProvider).error;
      showTopToast(
        context,
        why == null || why.isEmpty ? l10n.inviteFailed : why,
      );
    }
  }

  Future<void> _decline(BuildContext context) async {
    final declined = await showDeclineInviteSheet(context, invite);
    if (declined == true && context.mounted) {
      showTopToast(context, context.l10n.inviteDeclined);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final sending = ref.watch(
      packageInviteControllerProvider.select((s) => s.sending),
    );
    final price = _price(context, ref, invite);
    final date = invite.date == null
        ? l10n.inviteDateGuests
        : DateFormat('EEE d MMM y', locale).format(invite.date!);
    final host = invite.hostName;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label, style: AppTypography.body()),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title:
            Text(l10n.invitePageTitle, style: AppTypography.display(size: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: [
          Text(
            l10n.inviteEyebrow.toUpperCase(),
            style: AppTypography.label(),
          ),
          const SizedBox(height: 6),
          Text(
            host == null
                ? l10n.inviteHeadlineNoHost(invite.itemName, invite.packageName)
                : l10n.inviteHeadline(
                    host,
                    invite.itemName,
                    invite.packageName,
                  ),
            style: AppTypography.display(size: 22).copyWith(height: 1.25),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                row(l10n.invitePackage, invite.packageName),
                if (invite.city != null && invite.city!.isNotEmpty)
                  row(l10n.inviteArea, invite.city!),
                row(l10n.inviteDate, date),
                if (price != null) ...[
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.inviteOffered,
                          style: AppTypography.body(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(price, style: AppTypography.display(size: 18)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (invite.note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brCard,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.inviteTheirNote.toUpperCase(),
                    style: AppTypography.label(),
                  ),
                  const SizedBox(height: 6),
                  Text(invite.note!, style: AppTypography.body()),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.inviteAcceptHint,
            style: AppTypography.body(size: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: sending ? null : () => _decline(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      child: Text(
                        l10n.inviteDecline,
                        style: AppTypography.display(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: sending ? null : () => _join(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.inviteJoin,
                              style: AppTypography.display(
                                color: AppColors.onAccent,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks why, then declines. Returns true when the API took it.
Future<bool?> showDeclineInviteSheet(
  BuildContext context,
  PackageInvite invite,
) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => Consumer(
        builder: (context, ref, _) => DeclineReasonSheet(
          title: context.l10n.inviteDeclineTitle,
          subtitle: '${invite.packageName} · ${invite.itemName}',
          seenBy: context.l10n.inviteDeclineSeen,
          onDecline: (reason, note) async {
            final ok = await ref
                .read(packageInviteControllerProvider.notifier)
                .respond(invite, accept: false, reason: reason, note: note);
            return ok ? null : ref.read(packageInviteControllerProvider).error;
          },
        ),
      ),
    );

/// Asks why, from the decline reasons, and sends it with [onDecline]: a
/// Provider declining an invite, or an Event Foxer declining an application
/// (api#460). [onDecline] returns null when it was taken, else what went
/// wrong ('' when unknown). Pops true once taken.
class DeclineReasonSheet extends StatefulWidget {
  const DeclineReasonSheet({
    required this.title,
    required this.subtitle,
    required this.seenBy,
    required this.onDecline,
    super.key,
  });

  final String title;
  final String subtitle;

  /// Who sees the reason.
  final String seenBy;
  final Future<String?> Function(InviteDeclineReason reason, String note)
      onDecline;

  @override
  State<DeclineReasonSheet> createState() => _DeclineReasonSheetState();
}

class _DeclineReasonSheetState extends State<DeclineReasonSheet> {
  InviteDeclineReason? _reason;
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onDecline(reason, _note.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = _error;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _note,
          builder: (context, note, _) {
            final needsNote = _reason == InviteDeclineReason.other &&
                note.text.trim().isEmpty;
            final canSend = _reason != null && !needsNote && !_sending;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: AppTypography.display(size: 20)),
                const SizedBox(height: 6),
                Text(widget.subtitle, style: AppTypography.body(size: 13)),
                const SizedBox(height: 14),
                RadioGroup<InviteDeclineReason>(
                  groupValue: _reason,
                  onChanged: (r) => setState(() => _reason = r),
                  child: Column(
                    children: [
                      for (final r in InviteDeclineReason.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ReasonTile(
                            reason: r,
                            label: inviteReasonLabel(l10n, r),
                            selected: _reason == r,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.inviteDeclineNoteLabel,
                  style: AppTypography.body(size: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('invite-decline-note'),
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    counterText: '',
                    errorText:
                        needsNote ? l10n.inviteDeclineNoteRequired : null,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error.isEmpty ? l10n.inviteFailed : error,
                    style: AppTypography.body(size: 13, color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  widget.seenBy,
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                              color: AppColors.borderStrong,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.brMd,
                            ),
                          ),
                          child: Text(
                            l10n.inviteBack,
                            style: AppTypography.display(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 7,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: canSend ? _send : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.canvas,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.brMd,
                            ),
                          ),
                          child: Text(
                            l10n.inviteDeclineSend,
                            style: AppTypography.display(
                              color: AppColors.canvas,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.reason,
    required this.label,
    required this.selected,
  });

  final InviteDeclineReason reason;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceRaised : AppColors.clear,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(
          color: selected ? AppColors.textPrimary : AppColors.borderStrong,
        ),
      ),
      child: RadioListTile<InviteDeclineReason>(
        value: reason,
        dense: true,
        activeColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        title: Text(
          label,
          style: AppTypography.body(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
