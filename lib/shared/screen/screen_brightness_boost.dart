import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// What actually changes the screen. Swapped for a recorder in tests.
abstract class BrightnessBackend {
  Future<void> raise();
  Future<void> restore();
}

class _PluginBackend implements BrightnessBackend {
  // Application scope: it follows the app, not the whole phone, and the plugin
  // puts it back by itself when the app is closed or sent to the background.
  @override
  Future<void> raise() => ScreenBrightness().setApplicationScreenBrightness(1);

  @override
  Future<void> restore() =>
      ScreenBrightness().resetApplicationScreenBrightness();
}

/// Turns the screen up while anything holds it, and back down when none does.
///
/// Counted, because the Tickets list can show several QR codes at once: the
/// screen only goes back to normal when the last one is gone.
class ScreenBrightnessBoost {
  ScreenBrightnessBoost._();

  static BrightnessBackend backend = _PluginBackend();
  static int _holders = 0;

  static void acquire() {
    if (_holders++ == 0) unawaited(_run(backend.raise));
  }

  static void release() {
    if (_holders == 0) return;
    if (--_holders == 0) unawaited(_run(backend.restore));
  }

  /// The web, a desktop without a plugin, or a phone that refuses: the QR still
  /// works, the screen just stays as it was.
  static Future<void> _run(Future<void> Function() change) async {
    try {
      await change();
    } on Object {
      // Nothing to do; see above.
    }
  }
}

/// Keeps the screen bright while [child] is on screen and the user can see it.
///
/// "Can see it" means its tab is the one showing and its screen is the top one;
/// a tab kept alive behind another, or a page covered by a new one, lets go.
class BrightWhileVisible extends StatefulWidget {
  const BrightWhileVisible({required this.child, super.key});

  final Widget child;

  @override
  State<BrightWhileVisible> createState() => _BrightWhileVisibleState();
}

class _BrightWhileVisibleState extends State<BrightWhileVisible> {
  bool _held = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (visible && !_held) {
      ScreenBrightnessBoost.acquire();
      _held = true;
    } else if (!visible && _held) {
      ScreenBrightnessBoost.release();
      _held = false;
    }
  }

  @override
  void dispose() {
    if (_held) ScreenBrightnessBoost.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
