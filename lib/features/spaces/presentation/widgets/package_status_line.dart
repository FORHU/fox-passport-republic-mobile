import 'package:flutter/material.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';
import 'package:flutter_template/features/spaces/domain/package_standing.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_invites.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// One line saying where a package stands, for the Events tab (mobile#509):
/// "2 of 3 Suppliers agreed · 1 to replace", "Sent · the admin is checking
/// it". Null when there is nothing to say (an archived package).
({String text, Color color})? packageStatusLine(
  AppLocalizations l10n,
  PackageStanding package,
) {
  switch (package.stage) {
    case PackageStage.building:
      if (package.lines.isEmpty) {
        return (text: l10n.pkgLineNoSuppliers, color: AppColors.textMuted);
      }
      final toSwap = package.toSwap.length;
      final waiting = package.waiting.length;
      final parts = [
        l10n.pkgAgreedOf(package.acceptedCount, package.requiredCount),
        if (toSwap > 0) l10n.pkgToSwapCount(toSwap),
        if (waiting > 0) l10n.pkgWaitingCount(waiting),
      ];
      return (
        text: parts.join(' · '),
        color: toSwap > 0
            ? AppColors.error
            : waiting > 0
                ? AppColors.warning
                : AppColors.textSecondary,
      );
    case PackageStage.ready:
      return (text: l10n.pkgLineReady, color: AppColors.success);
    case PackageStage.inReview:
      return (text: l10n.pkgLineInReview, color: AppColors.textSecondary);
    case PackageStage.live:
      return (
        text: l10n.pkgLineLive(package.acceptedCount),
        color: AppColors.success,
      );
    case PackageStage.rejected:
      return (text: l10n.pkgLineRejected, color: AppColors.error);
    case PackageStage.archived:
      return null;
  }
}

/// The Supplier's reason and note for a decline, as the builder shows it:
/// `Price too low: "…"`. Null when they gave neither.
String? lineDeclineText(AppLocalizations l10n, LineInvite answer) {
  final reason = answer.reason;
  final note = answer.note;
  final label = reason == null ? null : inviteReasonLabel(l10n, reason);
  if (label != null && note != null) {
    return l10n.esInviteReasonNote(label, note);
  }
  return label ?? (note == null ? null : '“$note”');
}
