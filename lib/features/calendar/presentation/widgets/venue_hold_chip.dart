import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Where a booking at the person's venue stands with the venue: needs their
/// reply, held, or confirmed.
class VenueHoldChip extends StatelessWidget {
  const VenueHoldChip({required this.hold, super.key});

  final VenueHold hold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (hold) {
      VenueHold.awaitingReply => (l10n.calendarHoldAwaiting, AppColors.warning),
      VenueHold.held => (l10n.calendarHoldHeld, AppColors.textSecondary),
      VenueHold.confirmed => (l10n.calendarHoldConfirmed, AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(label, style: AppTypography.label(color: color)),
    );
  }
}
