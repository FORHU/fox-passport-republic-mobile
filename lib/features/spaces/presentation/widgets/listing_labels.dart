import 'package:flutter_template/l10n/generated/app_localizations.dart';

/// Names for a gear or service listing's codes, shared by the listing form
/// and its preview.
String listingCategoryLabel(AppLocalizations l10n, String code) =>
    switch (code) {
      'design' => l10n.listingCatDesign,
      'catering' => l10n.listingCatCatering,
      'service_staff' => l10n.listingCatStaff,
      'photography' => l10n.listingCatPhotography,
      'videography' => l10n.listingCatVideography,
      'dj' => l10n.listingCatDj,
      'live_band' => l10n.listingCatLiveBand,
      'mc' => l10n.listingCatMc,
      'furnitures' => l10n.listingCatFurniture,
      'sound_system' => l10n.listingCatSound,
      'decorations' => l10n.listingCatDecorations,
      'equipment' => l10n.listingCatEquipment,
      _ => l10n.listingCatOther,
    };

String listingRateLabel(AppLocalizations l10n, String code) => switch (code) {
      'hourly' => l10n.listingRateHourly,
      'daily' => l10n.listingRateDaily,
      'weekly' => l10n.listingRateWeekly,
      'monthly' => l10n.listingRateMonthly,
      'yearly' => l10n.listingRateYearly,
      _ => l10n.listingRateOneTime,
    };

String listingConditionLabel(AppLocalizations l10n, String code) =>
    switch (code) {
      'new' => l10n.listingConditionNew,
      'fair' => l10n.listingConditionFair,
      'refurbished' => l10n.listingConditionRefurbished,
      _ => l10n.listingConditionGood,
    };
