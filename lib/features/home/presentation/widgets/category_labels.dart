import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';

/// The words and icon for a bookable category (the API's name for it).
String categoryLabel(AppLocalizations l10n, String name) => switch (name) {
      'venues' => l10n.categoryVenues,
      'photography' => l10n.categoryPhotography,
      'videography' => l10n.categoryVideography,
      'dj' => l10n.categoryDj,
      'live_band' => l10n.categoryLiveBand,
      'mc' => l10n.categoryMc,
      'catering' => l10n.categoryCatering,
      'design' => l10n.categoryDesign,
      'service_staff' => l10n.categoryStaff,
      'entertainment' => l10n.categoryEntertainment,
      'sound_system' => l10n.categorySound,
      'decorations' => l10n.categoryDecor,
      'furnitures' => l10n.categoryFurniture,
      'equipment' => l10n.categoryEquipment,
      _ => _humanize(name),
    };

/// A category the app has no word for yet: "beach_resort" -> "Beach resort".
String _humanize(String name) {
  final spaced = name.replaceAll('_', ' ').trim();
  if (spaced.isEmpty) return name;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

IconData categoryIcon(String name) => switch (name) {
      'venues' => Icons.apartment_outlined,
      'photography' => Icons.photo_camera_outlined,
      'videography' => Icons.videocam_outlined,
      'dj' => Icons.album_outlined,
      'live_band' => Icons.music_note_outlined,
      'mc' => Icons.mic_none_rounded,
      'catering' => Icons.restaurant_outlined,
      'design' => Icons.palette_outlined,
      'service_staff' => Icons.badge_outlined,
      'entertainment' => Icons.theater_comedy_outlined,
      'sound_system' => Icons.speaker_outlined,
      'decorations' => Icons.celebration_outlined,
      'furnitures' => Icons.chair_outlined,
      'equipment' => Icons.build_outlined,
      _ => Icons.category_outlined,
    };

String occasionLabel(AppLocalizations l10n, Occasion occasion) =>
    switch (occasion) {
      Occasion.birthday => l10n.occasionBirthday,
      Occasion.wedding => l10n.occasionWedding,
      Occasion.corporate => l10n.occasionCorporate,
      Occasion.social => l10n.occasionSocial,
      Occasion.other => l10n.occasionOther,
    };
