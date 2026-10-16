import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/reviews/presentation/widgets/write_review_sheet.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/cancel_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/ticket_panel.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// One booking: status, event, when, a QR code to scan at the door, and the
/// two things you do with a ticket (wallet, directions).
class TicketCard extends ConsumerWidget {
  const TicketCard({required this.ticket, super.key});

  final Ticket ticket;

  /// Only a live booking that has not started can be cancelled.
  bool get _canCancel =>
      !ticket.isSample &&
      (ticket.status == 'pending' || ticket.status == 'confirmed') &&
      ticket.startAt.isAfter(DateTime.now());

  /// A booking that took place and has not been reviewed yet.
  bool get _canReview =>
      !ticket.isSample &&
      !ticket.hasReview &&
      (ticket.status == 'confirmed' || ticket.status == 'completed') &&
      ticket.endAt.isBefore(DateTime.now());

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    final posted = await showWriteReviewSheet(
      context,
      bookingId: ticket.id,
      title: ticket.eventName,
    );
    if (posted) ref.invalidate(pastTicketsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat('EEE d MMM', locale).format(ticket.startAt);
    final doors = DateFormat.jm(locale).format(ticket.startAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TicketPanel(
          borderColor: AppColors.border,
          top: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _status(l10n, ticket.status).toUpperCase(),
                      style: AppTypography.label(
                        color: _statusColor(ticket.status),
                      ),
                    ),
                    if (ticket.isSample)
                      Text(
                        l10n.sampleTag.toUpperCase(),
                        style: AppTypography.label(),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket.eventName,
                  style: AppTypography.display(size: 22),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _Fact(l10n.ticketDate, date)),
                    Expanded(child: _Fact(l10n.ticketDoors, doors)),
                    Expanded(
                      child: _Fact(
                        l10n.ticketGuests,
                        '${ticket.guestCount}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottom: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _Qr(ticket: ticket),
                if (ticket.ticketCode != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    ticket.ticketCode!,
                    style: AppTypography.label(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Action(
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.ticketAddToWallet,
                onTap: () => showTopToast(context, l10n.comingSoonWallet),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Action(
                icon: Icons.location_on_outlined,
                label: l10n.ticketDirections,
                onTap: () => _directions(context),
              ),
            ),
          ],
        ),
        if (_canReview)
          TextButton.icon(
            onPressed: () => unawaited(_review(context, ref)),
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            icon: const Icon(Icons.star_outline_rounded),
            label: Text(l10n.reviewWrite),
          ),
        if (_canCancel)
          TextButton(
            onPressed: () => showCancelSheet(context, ticket),
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            child: Text(
              l10n.ticketCancel,
              style: AppTypography.body(
                color: AppColors.error,
                weight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _directions(BuildContext context) async {
    final query = [ticket.eventName, ticket.city]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .join(', ');
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showTopToast(context, context.l10n.comingSoonMap);
    }
  }

  static String _status(AppLocalizations l10n, String status) =>
      switch (status) {
        'confirmed' => l10n.ticketStatusConfirmed,
        'pending' => l10n.ticketStatusPending,
        'completed' => l10n.ticketStatusCompleted,
        'cancelled' => l10n.ticketStatusCancelled,
        _ => status,
      };

  static Color _statusColor(String status) => switch (status) {
        'confirmed' => AppColors.accent,
        'pending' => AppColors.warning,
        'cancelled' => AppColors.error,
        _ => AppColors.textSecondary,
      };
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTypography.label()),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.display(size: 15),
        ),
      ],
    );
  }
}

class _Qr extends StatelessWidget {
  const _Qr({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ticket.isSample || ticket.ticketCode == null
          ? const Icon(
              Icons.qr_code_2_rounded,
              size: 72,
              color: AppColors.onLightSurface,
            )
          : QrImageView(
              data: ticket.ticketCode!,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.lightSurface,
            ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
