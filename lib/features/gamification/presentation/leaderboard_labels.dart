import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';

/// The label for a role chip and a row.
String roleLabel(AppLocalizations l10n, LeaderboardRole role) => switch (role) {
      LeaderboardRole.venue => l10n.leaderboardRoleVenue,
      LeaderboardRole.event => l10n.leaderboardRoleEvent,
      LeaderboardRole.providers => l10n.leaderboardRoleProviders,
    };

/// The short, singular label for a role on a row ("Venue").
String rolePillLabel(AppLocalizations l10n, LeaderboardRole role) =>
    switch (role) {
      LeaderboardRole.venue => l10n.leaderboardPillVenue,
      LeaderboardRole.event => l10n.leaderboardPillEvent,
      LeaderboardRole.providers => l10n.leaderboardPillProviders,
    };

/// The label for a tab of the Foxer board.
String foxerTabLabel(AppLocalizations l10n, FoxerTab tab) => switch (tab) {
      FoxerTab.topRated => l10n.leaderboardTabTopRated,
      FoxerTab.mostBooked => l10n.leaderboardMostBooked,
      FoxerTab.rising => l10n.leaderboardTabRising,
    };
