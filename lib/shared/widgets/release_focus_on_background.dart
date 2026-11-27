import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// On Android, clears the focused text field when the app goes to the
/// background (mobile#285).
///
/// A field that keeps its focus while the user is in another app does not
/// bring the keyboard back when it is tapped again: Flutter still thinks the
/// keyboard is open, so the tap asks for nothing. With the focus cleared, the
/// first tap after coming back focuses the field again and opens the keyboard.
///
/// `inactive` is left alone, so a notification shade or a system dialog over
/// the app does not close the keyboard.
class ReleaseFocusOnBackground extends StatefulWidget {
  const ReleaseFocusOnBackground({required this.child, super.key});

  final Widget child;

  @override
  State<ReleaseFocusOnBackground> createState() =>
      _ReleaseFocusOnBackgroundState();
}

class _ReleaseFocusOnBackgroundState extends State<ReleaseFocusOnBackground>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
