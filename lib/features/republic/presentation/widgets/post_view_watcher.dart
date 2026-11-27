import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_template/features/republic/data/post_view_tracker.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Calls [onSeen] once, when at least half of [child] has been on screen for
/// a second without leaving (the web's rule, app#303).
class PostViewWatcher extends StatefulWidget {
  const PostViewWatcher({
    required this.postId,
    required this.onSeen,
    required this.child,
    super.key,
  });

  final String postId;
  final VoidCallback onSeen;
  final Widget child;

  @override
  State<PostViewWatcher> createState() => _PostViewWatcherState();
}

class _PostViewWatcherState extends State<PostViewWatcher> {
  Timer? _dwell;
  bool _done = false;

  void _changed(VisibilityInfo info) {
    if (_done || !mounted) return;
    if (info.visibleFraction >= PostViewTracker.visibleRatio) {
      _dwell ??= Timer(PostViewTracker.dwell, () {
        _done = true;
        widget.onSeen();
      });
    } else {
      _dwell?.cancel();
      _dwell = null;
    }
  }

  @override
  void didUpdateWidget(PostViewWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A list can hand this spot to another post: start over for it.
    if (oldWidget.postId != widget.postId) {
      _dwell?.cancel();
      _dwell = null;
      _done = false;
    }
  }

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: ValueKey('post-view-${widget.postId}'),
        onVisibilityChanged: _changed,
        child: widget.child,
      );
}
