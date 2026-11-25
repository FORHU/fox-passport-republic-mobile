import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';
import 'package:flutter_template/features/spaces/domain/package_standing.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_status_line.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Opens a chat with a user; passed in by the routes so this feature does not
/// import messages.
typedef MessageUser = Future<void> Function(
  BuildContext context,
  String userId,
);

/// Where one of the Event Foxer's packages stands (mobile#509, canvas
/// "Waiting to publish"): each Supplier's answer, then what comes next. A
/// package is sent for review only once every required Supplier accepted
/// (api#469), so the steps are Suppliers → send → admin → live.
class PackageStatusPage extends ConsumerWidget {
  const PackageStatusPage({required this.eventId, this.onMessage, super.key});

  final String eventId;
  final MessageUser? onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final event = ref.watch(packageStandingProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          event.asData?.value.name.isNotEmpty ?? false
              ? event.asData!.value.name
              : l10n.pkgStatusTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.display(size: 20),
        ),
      ),
      body: event.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.pkgStatusNotFound,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(packageStandingProvider(eventId)),
        ),
        data: (e) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(packageStandingProvider(eventId));
            try {
              await ref.read(packageStandingProvider(eventId).future);
            } on Object {
              // The page shows its own error state with a retry.
            }
          },
          child: _Body(event: e, onMessage: onMessage),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.event, required this.onMessage});

  final SpaceListing event;
  final MessageUser? onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Only an event with a package reaches here (eventStanding checks it).
    final package = event.package!;
    final lines = [
      ...package.lines.where((l) => l.required),
      ...package.lines.where((l) => !l.required),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _StageHeader(package: package),
        const SizedBox(height: 20),
        Text(
          l10n.bookedEventSuppliers.toUpperCase(),
          style: AppTypography.label(),
        ),
        const SizedBox(height: 8),
        if (lines.isEmpty)
          Text(
            l10n.pkgNoLines,
            style: AppTypography.body(color: AppColors.textMuted),
          )
        else
          for (final line in lines)
            _LineCard(
              line: line,
              onMessage:
                  onMessage == null || line.supplierId == null || !line.waiting
                      ? null
                      : () => _message(context, line),
            ),
        const SizedBox(height: 20),
        Text(l10n.pkgNextTitle.toUpperCase(), style: AppTypography.label()),
        const SizedBox(height: 8),
        _Steps(package: package),
        const SizedBox(height: 24),
        if (package.stage == PackageStage.ready) ...[
          FilledButton(
            onPressed: () => unawaited(_submit(context, ref)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(l10n.esSubmit),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton(
          onPressed: () => unawaited(_openBuilder(context, ref)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(l10n.pkgOpenBuilder),
        ),
      ],
    );
  }

  void _refresh(WidgetRef ref) => ref
    ..invalidate(packageStandingProvider(event.id))
    ..invalidate(myEventsProvider);

  Future<void> _openBuilder(BuildContext context, WidgetRef ref) async {
    await context.push<void>(RouteNames.spaceEventStudioEdit(event.id));
    // The page may have been closed meanwhile; ref can't be used then.
    if (!context.mounted) return;
    _refresh(ref);
  }

  Future<void> _message(BuildContext context, PackageLine line) async {
    final open = onMessage;
    final userId = line.supplierId;
    if (open == null || userId == null) return;
    final failed = context.l10n.messageStartFailed;
    try {
      await open(context, userId);
    } on Object catch (e) {
      if (!context.mounted) return;
      showTopToast(
        context,
        e is AppException && e.message.isNotEmpty ? e.message : failed,
      );
    }
  }

  /// Sends the package for review; the API's reason is shown when it
  /// refuses.
  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.read(spacesRepositoryProvider).submitEvent(event.id);
      if (!context.mounted) return;
      _refresh(ref);
      showTopToast(context, l10n.esSubmitted);
    } on Object catch (e) {
      if (!context.mounted) return;
      showTopToast(
        context,
        e is AppException && e.message.isNotEmpty
            ? e.message
            : l10n.pkgSubmitFailed,
      );
    }
  }
}

/// The stage, in a bordered card: what is going on and what it waits for.
class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.package});

  final PackageStanding package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waiting = package.waiting.length;
    final toSwap = package.toSwap.length;
    final (eyebrow, title, body, color) = switch (package.stage) {
      PackageStage.building => (
          l10n.pkgStageBuilding,
          package.lines.isEmpty
              ? l10n.pkgHeadEmpty
              : toSwap > 0
                  ? l10n.pkgHeadToSwap(toSwap)
                  : l10n.pkgHeadWaiting(waiting),
          l10n.pkgBodyBuilding,
          toSwap > 0 ? AppColors.error : AppColors.warning,
        ),
      PackageStage.ready => (
          l10n.pkgStageReady,
          l10n.pkgHeadReady,
          l10n.pkgBodyReady,
          AppColors.success,
        ),
      PackageStage.inReview => (
          l10n.pkgStageInReview,
          l10n.pkgHeadInReview,
          l10n.pkgBodyInReview,
          AppColors.textSecondary,
        ),
      PackageStage.live => (
          l10n.pkgStageLive,
          l10n.pkgHeadLive,
          l10n.pkgBodyLive,
          AppColors.success,
        ),
      PackageStage.rejected => (
          l10n.pkgStageRejected,
          l10n.pkgHeadRejected,
          l10n.pkgBodyRejected,
          AppColors.error,
        ),
      PackageStage.archived => (
          l10n.pkgStageArchived,
          l10n.pkgHeadArchived,
          null,
          AppColors.textMuted,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: AppTypography.label(color: color)),
          const SizedBox(height: 6),
          Text(title, style: AppTypography.display(size: 20)),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(body, style: AppTypography.body(size: 13)),
          ],
        ],
      ),
    );
  }
}

/// One Supplier and their answer.
class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, this.onMessage});

  final PackageLine line;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = switch (line.kind) {
      PackageLineKind.venue => l10n.pkgKindVenue,
      PackageLineKind.gear => l10n.pkgKindGear,
      PackageLineKind.service => l10n.pkgKindService,
    };
    final detail = _detail(l10n, line, DateTime.now());
    final attention = line.required && line.needsAction;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: attention ? AppColors.error : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 15),
                ),
              ),
              const SizedBox(width: 8),
              _AnswerChip(line.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            line.required ? kind : '$kind · ${l10n.pkgOptionalNote}',
            style: AppTypography.body(size: 12),
          ),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail.$1,
              style: AppTypography.body(size: 12, color: detail.$2),
            ),
          ],
          if (onMessage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onMessage,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: EdgeInsets.zero,
                ),
                child: Text(l10n.pkgMessage(line.name)),
              ),
            ),
        ],
      ),
    );
  }

  /// Days left while waiting, the reason for a decline, or that it expired.
  static (String, Color)? _detail(
    AppLocalizations l10n,
    PackageLine line,
    DateTime now,
  ) {
    final invite = line.invite;
    if (invite == null) return null;
    switch (invite.status) {
      case InviteStatus.pending:
        final left = invite.daysLeft(now);
        if (left == null) return null;
        return (
          left == 0 ? l10n.esExpiresToday : l10n.esExpiresIn(left),
          AppColors.warning,
        );
      case InviteStatus.declined:
        final text = lineDeclineText(l10n, invite);
        return text == null ? null : (text, AppColors.textPrimary);
      case InviteStatus.expired:
        return (l10n.pkgExpiredNote, AppColors.textMuted);
      case InviteStatus.accepted:
      case InviteStatus.other:
        return null;
    }
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip(this.status);

  final InviteStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, icon, color) = switch (status) {
      InviteStatus.accepted || InviteStatus.other => (
          l10n.esInviteAccepted,
          Icons.check_rounded,
          AppColors.success
        ),
      InviteStatus.pending => (
          l10n.esInviteWaiting,
          Icons.schedule_rounded,
          AppColors.warning
        ),
      InviteStatus.declined => (
          l10n.esInviteDeclined,
          Icons.close_rounded,
          AppColors.error
        ),
      InviteStatus.expired => (
          l10n.esInviteExpired,
          Icons.timer_off_outlined,
          AppColors.textMuted
        ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.body(size: 12, color: color)),
      ],
    );
  }
}

/// Suppliers → send → admin → live, each done, current or still to come.
class _Steps extends StatelessWidget {
  const _Steps({required this.package});

  final PackageStanding package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stage = package.stage;
    final sent = stage == PackageStage.inReview ||
        stage == PackageStage.live ||
        stage == PackageStage.rejected;
    final done = [
      package.allAccepted || sent,
      sent,
      stage == PackageStage.live,
      stage == PackageStage.live,
    ];
    final labels = [
      l10n.pkgStepSuppliers,
      l10n.pkgStepSend,
      l10n.pkgStepReview,
      l10n.pkgStepLive,
    ];
    final current = done.indexOf(false);

    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _stepIcon(
                  done: done[i],
                  current: i == current,
                  // The admin said no.
                  failed: stage == PackageStage.rejected && i == 2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labels[i],
                    style: AppTypography.body(
                      color: done[i] || i == current
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stepIcon({
    required bool done,
    required bool current,
    required bool failed,
  }) {
    if (failed) {
      return const Icon(Icons.close_rounded, size: 20, color: AppColors.error);
    }
    if (done) {
      return const Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: AppColors.success,
      );
    }
    return Icon(
      current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      size: 20,
      color: current ? AppColors.accent : AppColors.textMuted,
    );
  }
}
