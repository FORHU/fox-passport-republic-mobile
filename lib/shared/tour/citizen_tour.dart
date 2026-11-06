import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the citizen tour points at for bottom tab [tab]. Its own ids, apart
/// from the Foxer spaces' tab keys, because a space's bar and this one can be
/// in the tree together and a key may be used only once.
String citizenTourTarget(int tab) => 'citizen-tab-$tab';

/// The key to put on bottom tab [tab] so the tour can find it.
GlobalKey citizenTabKey(int tab) => TourKeys.of(citizenTourTarget(tab));

/// The five cards of a citizen's first-run tour, one per bottom tab, in the
/// tab order of the bar.
List<TourStep> citizenTourSteps(AppLocalizations l10n) => [
      TourStep(
        icon: Icons.home_rounded,
        title: l10n.tourCitizenHomeTitle,
        body: l10n.tourCitizenHomeBody,
        target: citizenTourTarget(0),
      ),
      TourStep(
        icon: Icons.forum_rounded,
        title: l10n.tourCitizenRepublicTitle,
        body: l10n.tourCitizenRepublicBody,
        target: citizenTourTarget(1),
      ),
      TourStep(
        icon: Icons.event_available_rounded,
        title: l10n.tourCitizenBookingsTitle,
        body: l10n.tourCitizenBookingsBody,
        target: citizenTourTarget(2),
      ),
      TourStep(
        icon: Icons.chat_bubble_rounded,
        title: l10n.tourCitizenMessagesTitle,
        body: l10n.tourCitizenMessagesBody,
        target: citizenTourTarget(3),
      ),
      TourStep(
        icon: Icons.badge_rounded,
        title: l10n.tourCitizenPassportTitle,
        body: l10n.tourCitizenPassportBody,
        target: citizenTourTarget(4),
      ),
    ];

/// The key the tour is remembered under, per account and device.
String citizenTourSeenKey(String? userId) =>
    'citizenTourSeen.${userId ?? 'anon'}';

/// Counts every time the tour is asked for again, so the citizen shell knows
/// to play it.
final NotifierProvider<CitizenTourRestarts, int> citizenTourRestartProvider =
    NotifierProvider<CitizenTourRestarts, int>(CitizenTourRestarts.new);

class CitizenTourRestarts extends Notifier<int> {
  @override
  int build() => 0;

  void ask() => state++;
}

/// Plays the tour, once per account on this device unless [force] is set. It is
/// remembered the moment it opens, so skipping, finishing and quitting the app
/// halfway all count as seen. Returns whether it was shown.
///
/// Remembered on the device only: the server does not know yet, so a new phone
/// or a reinstall plays it again, and finishing pays nothing.
Future<bool> offerCitizenTour(
  BuildContext context,
  WidgetRef ref, {
  bool force = false,
}) async {
  final SharedPreferences prefs;
  try {
    prefs = ref.read(sharedPreferencesProvider);
  } on Object {
    // Without saved settings it could not be remembered, so it is not shown.
    return false;
  }
  final key = citizenTourSeenKey(ref.read(currentUserIdProvider));
  if (!force && (prefs.getBool(key) ?? false)) return false;
  await prefs.setBool(key, true);
  if (!context.mounted) return false;
  await showSpaceTour(context, citizenTourSteps(context.l10n));
  return true;
}

/// Plays the tour again from Settings: goes to Home, where the tabs are, and
/// asks the citizen shell to play it.
void restartCitizenTour(WidgetRef ref, BuildContext context, String home) {
  ref.read(citizenTourRestartProvider.notifier).ask();
  context.go(home);
}
