import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which video in the feed may play. Every video reports how much of it is on
/// screen; one at a time is chosen, like Facebook's feed. The one playing keeps
/// the turn until it scrolls out of view, so two on screen do not flip back
/// and forth; then the most visible takes over. Its value is the chosen id.
class FeedVideoFocus extends ValueNotifier<String?> {
  FeedVideoFocus() : super(null);

  /// Part of a video that must show before it can play.
  static const minVisible = 0.6;

  /// Sound in the feed, shared, off at first.
  final muted = ValueNotifier<bool>(true);

  final _visible = <String, double>{};
  bool _suspended = false;
  bool _disposed = false;

  /// [fraction] (0 to 1) of the video [id] is on screen now.
  void report(String id, double fraction) {
    if (_disposed) return;
    if (fraction >= minVisible) {
      _visible[id] = fraction;
    } else {
      _visible.remove(id);
    }
    _pick();
  }

  /// The video [id] left the screen or the page.
  void release(String id) {
    if (_disposed) return;
    _visible.remove(id);
    _pick();
  }

  /// Nothing plays while the feed is covered, such as by the Videos view.
  // ignore: avoid_positional_boolean_parameters
  void suspend(bool suspended) {
    if (_disposed || _suspended == suspended) return;
    _suspended = suspended;
    _pick();
  }

  void _pick() {
    if (_suspended || _visible.isEmpty) {
      value = null;
      return;
    }
    if (value != null && _visible.containsKey(value)) return;
    String? best;
    var bestFraction = 0.0;
    for (final entry in _visible.entries) {
      if (entry.value > bestFraction) {
        best = entry.key;
        bestFraction = entry.value;
      }
    }
    value = best;
  }

  @override
  void dispose() {
    _disposed = true;
    muted.dispose();
    super.dispose();
  }
}

final feedVideoFocusProvider = Provider<FeedVideoFocus>((ref) {
  final focus = FeedVideoFocus();
  ref.onDispose(focus.dispose);
  return focus;
});
