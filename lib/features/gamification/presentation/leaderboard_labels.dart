import 'package:flutter/material.dart';
import 'package:flutter_template/features/gamification/domain/citizen_board.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// The label for a role chip and a row.
String roleLabel(AppLocalizations l10n, LeaderboardRole role) => switch (role) {
      LeaderboardRole.venue => l10n.leaderboardRoleVenue,
      LeaderboardRole.event => l10n.leaderboardRoleEvent,
      LeaderboardRole.gear => l10n.leaderboardRoleGear,
      LeaderboardRole.services => l10n.leaderboardRoleServices,
      LeaderboardRole.performers => l10n.leaderboardRolePerformers,
    };

/// The short, singular label for a role on a row ("Venue").
String rolePillLabel(AppLocalizations l10n, LeaderboardRole role) =>
    switch (role) {
      LeaderboardRole.venue => l10n.leaderboardPillVenue,
      LeaderboardRole.event => l10n.leaderboardPillEvent,
      LeaderboardRole.gear => l10n.leaderboardPillGear,
      LeaderboardRole.services => l10n.leaderboardPillServices,
      LeaderboardRole.performers => l10n.leaderboardPillPerformers,
    };

/// The label for a tab of the Foxer board.
String foxerTabLabel(AppLocalizations l10n, FoxerTab tab) => switch (tab) {
      FoxerTab.topRated => l10n.leaderboardTabTopRated,
      FoxerTab.mostBooked => l10n.leaderboardMostBooked,
      FoxerTab.rising => l10n.leaderboardTabRising,
    };

/// The label for a tab of the citizen board.
String citizenTabLabel(AppLocalizations l10n, CitizenTab tab) => switch (tab) {
      CitizenTab.month => l10n.leaderboardTabMonth,
      CitizenTab.all => l10n.leaderboardTabAll,
      CitizenTab.city => l10n.leaderboardTabCity,
    };

/// "2026-11" as "November 2026"; empty when there is no month yet or it does
/// not parse.
String monthLabel(String? month, Locale locale) {
  if (month == null || month.isEmpty) return '';
  final parts = month.split('-');
  if (parts.length != 2) return '';
  final year = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (year == null || m == null || m < 1 || m > 12) return '';
  return DateFormat.yMMMM(locale.toString()).format(DateTime(year, m));
}
