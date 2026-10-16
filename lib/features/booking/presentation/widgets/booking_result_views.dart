import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// "You're booked": the booking is paid and the ticket is in the Tickets tab.
class BookingConfirmedView extends StatelessWidget {
  const BookingConfirmedView({
    required this.selection,
    required this.receipt,
    required this.onViewTicket,
    required this.onMessageOwner,
    super.key,
  });

  final BookingSelection selection;
  final BookingReceipt receipt;
  final VoidCallback onViewTicket;
  final VoidCallback onMessageOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = selection.date;
    final when =
        date == null ? '' : DateFormat('EEE d MMM', locale).format(date);

    return _ResultScaffold(
      icon: const _StatusBadge(
        color: AppColors.accent,
        filled: true,
        child: Icon(Icons.check_rounded, size: 34, color: AppColors.onAccent),
      ),
      title: l10n.bookBookedTitle,
      subtitle: l10n.bookBookedSub,
      body: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.bookConfirmed.toUpperCase(),
                    style: AppTypography.label(color: AppColors.accent),
                  ),
                  if (receipt.isSample)
                    Text(
                      l10n.bookSampleTag.toUpperCase(),
                      style: AppTypography.label(),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                selection.venue.title,
                style: AppTypography.display(size: 18),
              ),
              const SizedBox(height: 2),
              Text(
                '$when · ${l10n.guestsCount(selection.guests)}',
                style: AppTypography.body(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.borderStrong, height: 1),
              ),
              _KeyValue(
                label: l10n.bookReference,
                value: receipt.reference,
                mono: true,
              ),
              const SizedBox(height: 8),
              _KeyValue(
                label: l10n.bookTotalCharged,
                value: formatMoney(
                  receipt.totalAmount,
                  receipt.currency,
                  locale: locale,
                ),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 16,
              color: AppColors.accent,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.bookAttendHint,
                style: AppTypography.body(size: 12),
              ),
            ),
          ],
        ),
      ],
      actions: [
        _PrimaryButton(label: l10n.bookViewTicket, onTap: onViewTicket),
        const SizedBox(height: 10),
        _OutlineButton(
          label: l10n.bookMessageOwner,
          icon: Icons.chat_bubble_outline_rounded,
          onTap: onMessageOwner,
        ),
      ],
    );
  }
}

/// "Request sent": guests are over capacity, so the owner decides first and
/// nothing has been charged.
class BookingRequestSentView extends StatelessWidget {
  const BookingRequestSentView({
    required this.selection,
    required this.receipt,
    required this.onMessageOwner,
    required this.onBackHome,
    super.key,
  });

  final BookingSelection selection;
  final BookingReceipt receipt;
  final VoidCallback onMessageOwner;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return _ResultScaffold(
      icon: const _StatusBadge(
        color: AppColors.warning,
        child: Icon(
          Icons.hourglass_bottom_rounded,
          size: 30,
          color: AppColors.warning,
        ),
      ),
      title: l10n.bookRequestSentTitle,
      subtitle: l10n.bookRequestSentSub,
      body: [
        _Step(
          icon: Icons.mail_outline_rounded,
          title: l10n.bookReqDelivered,
          body: l10n.bookReqDeliveredBody(selection.guests),
        ),
        const SizedBox(height: 14),
        _Step(
          icon: Icons.notifications_none_rounded,
          title: l10n.bookNotified,
          body: l10n.bookNotifiedBody,
        ),
        const SizedBox(height: 14),
        _Step(
          icon: Icons.credit_card_rounded,
          title: l10n.bookPayAfter,
          body: l10n.bookPayAfterBody,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            children: [
              _KeyValue(
                label: l10n.bookReference,
                value: receipt.reference,
                mono: true,
              ),
              const SizedBox(height: 8),
              _KeyValue(
                label: l10n.bookAmountIfApproved,
                value: formatMoney(
                  receipt.totalAmount,
                  receipt.currency,
                  locale: locale,
                ),
                strong: true,
              ),
            ],
          ),
        ),
      ],
      actions: [
        _PrimaryButton(label: l10n.bookMessageOwner, onTap: onMessageOwner),
        const SizedBox(height: 10),
        _OutlineButton(label: l10n.bookBackHome, onTap: onBackHome),
      ],
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: AppRadius.brMd,
  border: Border.all(color: AppColors.border),
);

class _ResultScaffold extends StatelessWidget {
  const _ResultScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actions,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final List<Widget> body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            children: [
              Center(child: icon),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 24),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
              const SizedBox(height: 24),
              ...body,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: actions),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.color,
    required this.child,
    this.filled = false,
  });

  final Color color;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : color.withValues(alpha: 0.14),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brSm,
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.display(size: 14),
              ),
              const SizedBox(height: 2),
              Text(body, style: AppTypography.body(size: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.label,
    required this.value,
    this.mono = false,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(size: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: mono
                ? AppTypography.label(color: AppColors.textPrimary)
                : AppTypography.display(size: strong ? 16 : 14),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
        child: Text(
          label,
          style: AppTypography.display(color: AppColors.onAccent),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTypography.display(size: 15)),
          ],
        ),
      ),
    );
  }
}
