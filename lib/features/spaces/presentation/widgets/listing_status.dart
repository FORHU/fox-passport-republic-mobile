import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// A venue's or event's status word as the person reads it, or null for one
/// the app does not know.
String? listingStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'draft' => l10n.listingStatusDraft,
      'pending' => l10n.listingStatusPending,
      'available' || 'published' || 'reserved' => l10n.listingStatusLive,
      'rejected' => l10n.listingStatusRejected,
      'archived' || 'paused' => l10n.listingStatusArchived,
      _ => null,
    };

/// Live is green, rejected is red, anything else is quiet.
Color listingStatusColor(String status) => switch (status) {
      'available' || 'published' || 'reserved' => AppColors.success,
      'rejected' => AppColors.error,
      'pending' => AppColors.warning,
      _ => AppColors.textMuted,
    };
