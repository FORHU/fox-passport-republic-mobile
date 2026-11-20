import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link and says whether it opened.
typedef LinkOpener = Future<bool> Function(Uri link);

/// How a turn in Stripe's form ended.
enum StripeFormOutcome {
  /// Stripe sent the person back to the app: the form is done or saved.
  returned,

  /// Stripe's single-use link expired: open a new one.
  expired,

  /// The person closed the form themselves.
  closed,

  /// Opened somewhere the app can't follow (a web tab, the system browser);
  /// the app finds out when it is in front again.
  openedElsewhere,

  /// It couldn't be opened at all.
  failed,
}

/// Runs Stripe's form and says how it ended.
typedef StripeFormRunner = Future<StripeFormOutcome> Function(Uri link);

/// The app's own scheme. Stripe can't send people to it directly (it only
/// takes https), so the API points Stripe at the web app's handoff pages,
/// which open `foxpassport://app/stripe/return` or `/refresh` (mobile#476).
const String kStripeCallbackScheme = 'foxpassport';

/// What Stripe's handoff link means. Anything but `/stripe/refresh` counts
/// as a return.
StripeFormOutcome outcomeForCallback(Uri callback) =>
    callback.path == '/stripe/refresh'
        ? StripeFormOutcome.expired
        : StripeFormOutcome.returned;

/// Stripe's form in a browser inside the app (Custom Tabs on Android,
/// SFSafariViewController on iOS), so the person stays in FoxPassport and
/// comes straight back. The web build has no in-app browser: a new tab. A
/// phone without an in-app browser gets the system browser instead.
Future<bool> openInAppBrowser(Uri link) async {
  Future<bool> open(LaunchMode mode) async {
    try {
      return await launchUrl(link, mode: mode);
    } on Object {
      return false;
    }
  }

  if (kIsWeb) return open(LaunchMode.platformDefault);
  return await open(LaunchMode.inAppBrowserView) ||
      await open(LaunchMode.externalApplication);
}

/// Stripe's form in an auth session (Custom Tabs on Android,
/// ASWebAuthenticationSession on iOS) that closes by itself as soon as the
/// handoff page opens the app's link, so the person never has to close the
/// browser by hand. Falls back to [openInAppBrowser] where that isn't
/// available, and on the web.
Future<StripeFormOutcome> runStripeForm(Uri link) async {
  Future<StripeFormOutcome> fallback() async => await openInAppBrowser(link)
      ? StripeFormOutcome.openedElsewhere
      : StripeFormOutcome.failed;

  if (kIsWeb) return fallback();
  try {
    final callback = await FlutterWebAuth2.authenticate(
      url: link.toString(),
      callbackUrlScheme: kStripeCallbackScheme,
    );
    return outcomeForCallback(Uri.parse(callback));
  } on PlatformException catch (e) {
    if (e.code == 'CANCELED') return StripeFormOutcome.closed;
    return fallback();
  } on Object {
    return fallback();
  }
}

final Provider<StripeFormRunner> stripeFormRunnerProvider =
    Provider<StripeFormRunner>((ref) => runStripeForm);

final Provider<PayoutSetupController> payoutSetupControllerProvider =
    Provider<PayoutSetupController>((ref) {
  final controller = PayoutSetupController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// How [PayoutSetupController.open] ended, for the page that called it.
enum PayoutSetupResult {
  /// No link could be had, or it couldn't be opened.
  failed,

  /// The person finished or saved Stripe's form and is back in the app.
  returned,

  /// The person closed the form, or it opened outside the app.
  left,
}

/// Starts or finishes the person's payout setup (Stripe Connect onboarding)
/// from the app (mobile#465). It used to open the web app's onboarding page
/// in the phone's browser, where the person usually wasn't signed in.
class PayoutSetupController {
  PayoutSetupController(this._ref);

  /// A run of expired links is cut off here rather than reopened forever.
  static const int maxLinks = 3;

  final Ref _ref;
  AppLifecycleListener? _onReturn;

  /// Asks the API for Stripe's link and opens it. When Stripe says the link
  /// expired, asks for a new one. Status and payouts are read again
  /// whenever the person is back.
  Future<PayoutSetupResult> open() async {
    for (var i = 0; i < maxLinks; i++) {
      final Uri link;
      try {
        // The web build can't be reopened by the app's link.
        link = await _ref
            .read(spacesRepositoryProvider)
            .payoutSetupLink(returnToApp: !kIsWeb);
      } on Object {
        return PayoutSetupResult.failed;
      }
      switch (await _ref.read(stripeFormRunnerProvider)(link)) {
        case StripeFormOutcome.expired:
          continue;
        case StripeFormOutcome.returned:
          refresh();
          return PayoutSetupResult.returned;
        case StripeFormOutcome.closed:
          refresh();
          return PayoutSetupResult.left;
        case StripeFormOutcome.openedElsewhere:
          _refreshOnReturn();
          return PayoutSetupResult.left;
        case StripeFormOutcome.failed:
          return PayoutSetupResult.failed;
      }
    }
    refresh();
    return PayoutSetupResult.left;
  }

  /// Reads the setup status and payouts again. Stripe tells the API when the
  /// account can be paid (its webhook), so this may take a moment to change.
  void refresh() {
    _ref
      ..invalidate(stripeStatusProvider)
      ..invalidate(payoutsProvider);
  }

  /// Once, when the app is in front again after Stripe's form.
  void _refreshOnReturn() {
    _onReturn?.dispose();
    _onReturn = AppLifecycleListener(
      onResume: () {
        _onReturn?.dispose();
        _onReturn = null;
        refresh();
      },
    );
  }

  void dispose() {
    _onReturn?.dispose();
    _onReturn = null;
  }
}
