import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Asks a venue (or a Provider) why it turns down a booking, and whether to
/// block the day too (mobile#511, canvas "Decline reasons"). Returns the
/// choice, or null when they keep the booking; the caller sends it.
Future<BookingDecline?> showBookingDeclineSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String confirmLabel,
  required bool isVenue,
  String? blockDate,
}) =>
    showModalBottomSheet<BookingDecline>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => BookingDeclineSheet(
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        isVenue: isVenue,
        blockDate: blockDate,
      ),
    );

class BookingDeclineSheet extends StatefulWidget {
  const BookingDeclineSheet({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.isVenue,
    this.blockDate,
    super.key,
  });

  final String title;
  final String subtitle;
  final String confirmLabel;

  /// A venue says "Closed that day"; gear and services "Not available".
  final bool isVenue;

  /// The day to offer blocking, already formatted; null hides the option
  /// (gear, services, or no date).
  final String? blockDate;

  @override
  State<BookingDeclineSheet> createState() => _BookingDeclineSheetState();
}

class _BookingDeclineSheetState extends State<BookingDeclineSheet> {
  BookingDeclineReason? _reason;
  bool _blockDay = false;

  /// Once the person ticks or unticks it, the reason stops changing it.
  bool _blockTouched = false;

  void _pick(BookingDeclineReason? reason) => setState(() {
        _reason = reason;
        if (!_blockTouched && reason != null) {
          _blockDay = reason.blocksDayByDefault;
        }
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = _reason;
    final blockDate = widget.blockDate;
    final reasons = [
      (
        BookingDeclineReason.alreadyBooked,
        l10n.bookingReasonAlreadyBooked,
        null
      ),
      if (widget.isVenue)
        (
          BookingDeclineReason.closed,
          l10n.bookingReasonClosed,
          l10n.bookingReasonClosedHint,
        )
      else
        (BookingDeclineReason.closed, l10n.bookingReasonUnavailable, null),
      (
        BookingDeclineReason.notSuitable,
        l10n.bookingReasonNotSuitable,
        l10n.bookingReasonNotSuitableHint,
      ),
      (BookingDeclineReason.other, l10n.bookingReasonOther, null),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppTypography.display(size: 20)),
            const SizedBox(height: 6),
            Text(widget.subtitle, style: AppTypography.body(size: 13)),
            const SizedBox(height: 14),
            Text(
              l10n.bookingDeclineReasonLabel.toUpperCase(),
              style: AppTypography.label(),
            ),
            const SizedBox(height: 8),
            RadioGroup<BookingDeclineReason>(
              groupValue: reason,
              onChanged: _pick,
              child: Column(
                children: [
                  for (final (value, label, hint) in reasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: reason == value
                            ? AppColors.surfaceRaised
                            : AppColors.clear,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                          side: BorderSide(
                            color: reason == value
                                ? AppColors.textPrimary
                                : AppColors.borderStrong,
                          ),
                        ),
                        child: RadioListTile<BookingDeclineReason>(
                          value: value,
                          dense: true,
                          activeColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd,
                          ),
                          title: Text(
                            label,
                            style: AppTypography.body(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: hint == null
                              ? null
                              : Text(
                                  hint,
                                  style: AppTypography.body(size: 12),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (blockDate != null)
              CheckboxListTile(
                key: const Key('booking-decline-block-day'),
                value: _blockDay,
                onChanged: (v) => setState(() {
                  _blockDay = v ?? false;
                  _blockTouched = true;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                checkColor: AppColors.onAccent,
                title: Text(
                  l10n.bookingDeclineBlockDay(blockDate),
                  style: AppTypography.body(color: AppColors.textPrimary),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      child: Text(
                        l10n.bookingDeclineKeep,
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
                      onPressed: reason == null
                          ? null
                          : () => Navigator.of(context).pop(
                                BookingDecline(
                                  reason: reason,
                                  blockDay: blockDate != null && _blockDay,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd,
                        ),
                      ),
                      child: Text(
                        widget.confirmLabel,
                        style: AppTypography.display(color: AppColors.canvas),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
