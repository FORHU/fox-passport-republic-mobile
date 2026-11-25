import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/package_invites_repository.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/booking_decline_sheet.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_invites.dart';
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

/// Asks why the person turns down [request] and whether to block the day
/// (mobile#511); null when they keep it.
Future<BookingDecline?> _askWhy(
  BuildContext context,
  VenueRequest request, {
  required String confirmLabel,
}) {
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final start = request.startAt;
  final day = start == null ? null : DateFormat.MMMEd(locale).format(start);
  final isVenue = request.kind == RequestKind.venue;
  return showBookingDeclineSheet(
    context,
    title: isVenue
        ? l10n.bookingDeclineTitleVenue(request.venueName)
        : l10n.bookingDeclineTitleItem,
    subtitle: [request.eventName, if (day != null) day].join(' · '),
    confirmLabel: confirmLabel,
    isVenue: isVenue,
    // Only a venue's calendar can be blocked, and only on a known day.
    blockDate: isVenue && request.venueId != null ? day : null,
  );
}

/// Blocks the event's day on the venue's calendar after a decline; false
/// when it didn't go through (the decline still stands).
Future<bool> _blockDay(WidgetRef ref, VenueRequest request) async {
  final venueId = request.venueId;
  final start = request.startAt;
  if (venueId == null || start == null) return false;
  try {
    await ref
        .read(spacesRepositoryProvider)
        .blockDay(venueId, DateTime(start.year, start.month, start.day));
    return true;
  } on Object {
    return false;
  }
}

/// Accepts or declines a request for one of the person's venues, asking why
/// before a decline (and whether to block the day), and says how it went.
/// Shared by the Requests list and the Overview.
Future<void> answerVenueRequest(
  BuildContext context,
  WidgetRef ref,
  VenueRequest request, {
  required bool accept,
}) async {
  final l10n = context.l10n;
  BookingDecline? decline;
  if (!accept) {
    decline = await _askWhy(
      context,
      request,
      confirmLabel: l10n.requestDecline,
    );
    if (decline == null || !context.mounted) return;
  }
  try {
    await ref
        .read(spacesRepositoryProvider)
        .reviewVenueRequest(request.id, accept: accept, kind: request.kind);
    final blocked =
        !(decline?.blockDay ?? false) || await _blockDay(ref, request);
    ref
      ..invalidate(venueRequestsProvider)
      ..invalidate(supplyRequestsProvider);
    if (context.mounted) {
      showTopToast(
        context,
        accept
            ? l10n.requestAccepted
            : blocked
                ? l10n.requestDeclined
                : l10n.bookingDeclineBlockFailed,
      );
    }
  } on Object {
    if (context.mounted) showTopToast(context, l10n.requestActionFailed);
  }
}

/// Leaves an event that is already booked: asks why first (the reason picks
/// the cause the API takes), then tells the event host and the citizen. Only
/// offered while the booking is not paid; if it has been paid since, the API
/// refuses and its reason is shown.
Future<void> declineBookedRequest(
  BuildContext context,
  WidgetRef ref,
  VenueRequest request,
) async {
  final l10n = context.l10n;
  final decline = await _askWhy(
    context,
    request,
    confirmLabel: l10n.requestDeclineBooked,
  );
  if (decline == null || !context.mounted) return;
  try {
    await ref.read(spacesRepositoryProvider).declineBookedItem(
          request.id,
          kind: request.kind,
          cause: decline.reason.cause,
        );
    final blocked = !decline.blockDay || await _blockDay(ref, request);
    ref
      ..invalidate(venueRequestsProvider)
      ..invalidate(supplyRequestsProvider);
    if (context.mounted) {
      showTopToast(
        context,
        blocked ? l10n.requestDeclinedBooked : l10n.bookingDeclineBlockFailed,
      );
    }
  } on Object catch (e) {
    if (!context.mounted) return;
    showTopToast(
      context,
      e is AppException && e.message.isNotEmpty
          ? e.message
          : l10n.requestActionFailed,
    );
  }
}

/// Requests for your venues: people adding a venue of yours to their event.
/// The ones that need a reply come first, with Accept and Decline.
class VenueRequestsPage extends ConsumerStatefulWidget {
  const VenueRequestsPage({this.provider, super.key});

  /// Set in a provider's space, for requests for their gear or services
  /// rather than venues.
  final ProviderKind? provider;

  @override
  ConsumerState<VenueRequestsPage> createState() => _VenueRequestsPageState();
}

class _VenueRequestsPageState extends ConsumerState<VenueRequestsPage> {
  /// Package invites (mobile#491) instead of booking requests.
  bool _invites = false;

  ProviderKind? get provider => widget.provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = provider == null
        ? venueRequestsProvider
        : supplyRequestsProvider(provider!.request);
    final requests = ref.watch(source);
    final bookingCount = requests.value?.where((r) => r.needsReply).length;
    // Each space answers invites for its own kind of listing only.
    final kind = provider?.request ?? RequestKind.venue;
    final inviteCount = ref
        .watch(packageInvitesProvider)
        .value
        ?.where((i) => i.isFor(kind) && i.status == InviteStatus.pending)
        .length;

    String tab(String label, int? count) =>
        count == null || count == 0 ? label : l10n.inviteTabCount(label, count);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: SpaceAppBar(title: l10n.requestsTitle),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _TabChip(
                  label: tab(l10n.inviteTabBookings, bookingCount),
                  selected: !_invites,
                  onTap: () => setState(() => _invites = false),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: tab(l10n.inviteTabInvites, inviteCount),
                  selected: _invites,
                  onTap: () => setState(() => _invites = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: _invites
                ? RefreshIndicator(
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    onRefresh: () => ref.refresh(packageInvitesProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [PackageInvitesView(kind: kind)],
                    ),
                  )
                : _bookings(context, requests),
          ),
        ],
      ),
    );
  }

  Widget _bookings(
    BuildContext context,
    AsyncValue<List<VenueRequest>> requests,
  ) {
    final l10n = context.l10n;
    final refreshable = provider == null
        ? venueRequestsProvider
        : supplyRequestsProvider(provider!.request);
    return requests.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => AppStateView(
        kind: AppStateKind.error,
        title: l10n.apiLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(refreshable),
      ),
      data: (list) => RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.refresh(refreshable.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(
              switch (provider) {
                null => l10n.requestsIntro,
                ProviderKind.gear => l10n.requestsIntroGear,
                ProviderKind.services => l10n.requestsIntroServices,
              },
              style: AppTypography.body(size: 13),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  switch (provider) {
                    null => l10n.requestsEmpty,
                    ProviderKind.gear => l10n.requestsEmptyGear,
                    ProviderKind.services => l10n.requestsEmptyServices,
                  },
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
                  onDeclineBooked: request.canDecline
                      ? () => unawaited(
                            declineBookedRequest(context, ref, request),
                          )
                      : null,
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

/// "Bookings" / "Package invites", as the canvas inbox switches them.
class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.textPrimary : AppColors.clear,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.textPrimary : AppColors.borderStrong,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.body(
                size: 13,
                weight: FontWeight.w600,
                color: selected
                    ? AppColors.onLightSurface
                    : AppColors.textSecondary,
              ),
            ),
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
    this.onDeclineBooked,
    super.key,
  });

  final VenueRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Leaving an event that is already booked. Null when it is not offered
  /// (the request is still waiting for a reply, or the booking is paid).
  final VoidCallback? onDeclineBooked;

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
                    _StatusChip(status: request.status),
                  ],
                ),
              ),
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
          if (onDeclineBooked != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDeclineBooked,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.brPill,
                  ),
                ),
                child: Text(l10n.requestDeclineBooked),
              ),
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
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(text, style: AppTypography.label(color: color)),
    );
  }
}
