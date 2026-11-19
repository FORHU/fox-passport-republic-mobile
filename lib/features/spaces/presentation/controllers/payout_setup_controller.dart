import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link and says whether it opened.
typedef LinkOpener = Future<bool> Function(Uri link);

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

final Provider<LinkOpener> payoutSetupOpenerProvider =
    Provider<LinkOpener>((ref) => openInAppBrowser);

final Provider<PayoutSetupController> payoutSetupControllerProvider =
    Provider<PayoutSetupController>((ref) {
  final controller = PayoutSetupController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Starts or finishes the person's payout setup (Stripe Connect onboarding)
/// from the app (mobile#465). It used to open the web app's onboarding page
/// in the phone's browser, where the person usually wasn't signed in.
class PayoutSetupController {
  PayoutSetupController(this._ref);

  final Ref _ref;
  AppLifecycleListener? _onReturn;

  /// Asks the API for Stripe's link and opens it. False when the link
  /// couldn't be had (no permission, offline) or opened.
  Future<bool> open() async {
    final Uri link;
    try {
      link = await _ref.read(spacesRepositoryProvider).payoutSetupLink();
    } on Object {
      return false;
    }
    final opened = await _ref.read(payoutSetupOpenerProvider)(link);
    if (opened) _refreshOnReturn();
    return opened;
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
