import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_tour.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/onboarding/onboarding_repository.dart';
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

/// Plays the tour, once per account unless [force] is set. It is remembered on
/// the device the moment it opens, so skipping, finishing and quitting the app
/// halfway all count as seen. The server is told when it closes, which pays the
/// introduction reward once, and a tour it already has on record is not played
/// again on a new phone or after a reinstall. Returns whether it was shown.
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
  if (!force) {
    if (prefs.getBool(key) ?? false) return false;
    if (await _tourOnRecord(ref)) {
      await prefs.setBool(key, true);
      return false;
    }
  }
  await prefs.setBool(key, true);
  if (!context.mounted) return false;
  await showSpaceTour(context, citizenTourSteps(context.l10n));
  unawaited(_reportTour(ref));
  return true;
}

/// Whether the server already has this account's tour. When it cannot be
/// asked, the tour plays, which is what it did before the server knew.
Future<bool> _tourOnRecord(WidgetRef ref) async {
  try {
    final steps = await ref.read(onboardingRepositoryProvider).completedSteps();
    return steps.contains(OnboardingStep.intro);
  } on Object {
    return false;
  }
}

/// Tells the server the tour is done, then refreshes what shows its reward.
/// Replaying from Settings reports too, so someone who saw the tour before the
/// server kept track is credited. A failure is ignored: the next play reports
/// it again, and the server pays once.
Future<void> _reportTour(WidgetRef ref) async {
  try {
    await ref.read(onboardingRepositoryProvider).complete(OnboardingStep.intro);
    ref
      ..invalidate(onboardingStepsProvider)
      ..invalidate(walletProvider);
  } on Object {
    // Nothing to show for it.
  }
}

/// Plays the tour again from Settings: goes to Home, where the tabs are, and
/// asks the citizen shell to play it.
void restartCitizenTour(WidgetRef ref, BuildContext context, String home) {
  ref.read(citizenTourRestartProvider.notifier).ask();
  context.go(home);
}
