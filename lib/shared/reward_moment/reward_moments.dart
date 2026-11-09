import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/reward_moment/rank_up_sheet.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_template/shared/reward_moment/reward_sheet.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The newest grant the person has seen, per account, on this phone.
String rewardSeenAtKey(String userId) => 'rewardSeenAt.$userId';

/// The rank the person last saw, per account, on this phone.
String rewardSeenRankKey(String userId) => 'rewardSeenRank.$userId';

bool _checking = false;

/// For tests: a check still waiting on an open sheet when a test ends would
/// otherwise make the next test's check return at once.
@visibleForTesting
void resetRewardMomentGuard() => _checking = false;

/// The name of the event the booking [bookingId] was for, found among the
/// person's tickets; null when there is no booking or it cannot be found.
Future<String?> _eventNameFor(WidgetRef ref, String? bookingId) async {
  if (bookingId == null) return null;
  try {
    final tickets = await ref.read(pastTicketsProvider.future);
    for (final t in tickets) {
      if (t.id == bookingId && t.eventName.trim().isNotEmpty) {
        return t.eventName;
      }
    }
  } on Object {
    // Without the name the sheet simply says it more generally.
  }
  return null;
}

/// Looks at the Coins history for XP and Coins that arrived since the person
/// last looked, and for a new rank, and shows the reward sheet and then the
/// rank-up sheet. Run it when the app opens and comes back to the front.
///
/// The server does not push these to the person who earned them (a Foxer
/// checks them in, for one), so the app asks. What was seen is remembered
/// before a sheet opens, so closing the app halfway never replays one; and the
/// first time on a phone nothing is shown, only remembered. Anything that
/// cannot be loaded is skipped quietly: the next check will find it again.
Future<void> showPendingRewardMoments(
  BuildContext context,
  WidgetRef ref,
) async {
  if (_checking) return;
  _checking = true;
  try {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final SharedPreferences prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } on Object {
      return;
    }

    ref.invalidate(walletProvider);
    final wallet = await ref.read(walletProvider.future);

    final seenAtText = prefs.getString(rewardSeenAtKey(userId));
    final moments = detectRewardMoments(
      history: wallet.history,
      level: wallet.level,
      seenAt: seenAtText == null ? null : DateTime.tryParse(seenAtText),
      seenRank: prefs.getInt(rewardSeenRankKey(userId)),
    );
    if (moments.seenAt != null) {
      await prefs.setString(
        rewardSeenAtKey(userId),
        moments.seenAt!.toIso8601String(),
      );
    }
    await prefs.setInt(rewardSeenRankKey(userId), moments.seenRank);
    if (moments.isEmpty || !context.mounted) return;

    var toPassport = false;
    var toBadges = false;
    var toHowItWorks = false;

    final reward = moments.reward;
    if (reward != null) {
      PassportSummary? passport;
      try {
        ref.invalidate(passportProvider);
        passport = await ref.read(passportProvider.future);
      } on Object {
        passport = null;
      }
      final eventName = await _eventNameFor(ref, reward.bookingId);
      if (!context.mounted) return;
      final choice = await showRewardSheet(
        context,
        reward: reward,
        passport: passport,
        eventName: eventName,
      );
      toPassport = choice == RewardSheetChoice.viewPassport;
      toHowItWorks = choice == RewardSheetChoice.learnMore;
    }

    final rankUp = moments.rankUp;
    if (rankUp != null && context.mounted) {
      final seeBadges = await showRankUpSheet(
        context,
        rankUp: rankUp,
        rankName: wallet.rank,
        level: wallet.level,
      );
      toBadges = seeBadges ?? false;
    }

    if (!context.mounted) return;
    if (toBadges) {
      context.go(RouteNames.passportBadges);
    } else if (toPassport) {
      context.go(RouteNames.passport);
    } else if (toHowItWorks) {
      await context.push(RouteNames.howItWorks);
    }
  } on Object {
    // Rewards are a nicety: a failure here never gets in the person's way.
  } finally {
    _checking = false;
  }
}
