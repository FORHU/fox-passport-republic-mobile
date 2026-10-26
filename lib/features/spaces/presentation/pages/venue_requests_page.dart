import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Accepts or declines a request for one of the person's venues, asking first
/// before a decline, and says how it went. Shared by the Requests list and the
/// Overview.
Future<void> answerVenueRequest(
  BuildContext context,
  WidgetRef ref,
  VenueRequest request, {
  required bool accept,
}) async {
  final l10n = context.l10n;
  if (!accept) {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.requestDeclineTitle),
        content: Text(l10n.requestDeclineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.messageCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.requestDecline,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
  }
  try {
    await ref
        .read(spacesRepositoryProvider)
        .reviewVenueRequest(request.id, accept: accept);
    ref.invalidate(venueRequestsProvider);
    if (context.mounted) {
      showTopToast(
        context,
        accept ? l10n.requestAccepted : l10n.requestDeclined,
      );
    }
  } on Object {
    if (context.mounted) showTopToast(context, l10n.requestActionFailed);
  }
}

/// Requests for your venues: people adding a venue of yours to their event.
/// The ones that need a reply come first, with Accept and Decline.
class VenueRequestsPage extends ConsumerWidget {
  const VenueRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(venueRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.requestsTitle, style: AppTypography.display(size: 18)),
        actions: const [SpaceTopActions()],
      ),
      body: requests.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(venueRequestsProvider),
        ),
        data: (list) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(venueRequestsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(l10n.requestsIntro, style: AppTypography.body(size: 13)),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    l10n.requestsEmpty,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                )
              else
                for (final request in list) ...[
                  VenueRequestCard(
                    request: request,
                    onAccept: () => unawaited(
                      answerVenueRequest(context, ref, request, accept: true),
                    ),
                    onDecline: () => unawaited(
                      answerVenueRequest(context, ref, request, accept: false),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One request for a venue: what it is for, who asked, the price, and Accept
/// and Decline while it waits for a reply.
class VenueRequestCard extends ConsumerWidget {
  const VenueRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final VenueRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final when = request.startAt == null
        ? null
        : DateFormat('EEE d MMM', locale).format(request.startAt!);
    final replyBy = request.replyBy == null
        ? null
        : DateFormat.MMMd(locale).add_jm().format(request.replyBy!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(
          color: request.needsReply ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoBox(url: request.imageUrl, width: 56, height: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.venueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(),
                    ),
                    Text(
                      [request.eventName, if (when != null) when].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(size: 13),
                    ),
                    if (request.clientName != null)
                      Text(
                        l10n.requestFrom(request.clientName!),
                        style: AppTypography.body(size: 12),
                      ),
                  ],
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          if (request.price != null) ...[
            const SizedBox(height: 10),
            Text(
              money.format(request.price!, kBaseCurrency, locale: locale),
              style: AppTypography.display(size: 15),
            ),
          ],
          if (request.needsReply) ...[
            if (replyBy != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.requestReplyBy(replyBy),
                style: AppTypography.body(size: 12, color: AppColors.warning),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                    child: Text(l10n.requestDecline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                    child: Text(l10n.requestAccept),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RequestStatus status;

  static String label(AppLocalizations l10n, RequestStatus status) =>
      switch (status) {
        RequestStatus.awaitingYou => l10n.requestStatusAwaiting,
        RequestStatus.pending => l10n.requestStatusPending,
        RequestStatus.approved => l10n.requestStatusApproved,
        RequestStatus.rejected => l10n.requestStatusRejected,
        RequestStatus.cancelled => l10n.requestStatusCancelled,
        RequestStatus.other => '',
      };

  @override
  Widget build(BuildContext context) {
    final text = label(context.l10n, status);
    if (text.isEmpty) return const SizedBox.shrink();
    final color = switch (status) {
      RequestStatus.awaitingYou => AppColors.accent,
      RequestStatus.approved => AppColors.success,
      RequestStatus.rejected || RequestStatus.cancelled => AppColors.error,
      _ => AppColors.textMuted,
    };
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(text, style: AppTypography.label(color: color)),
    );
  }
}
