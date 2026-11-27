import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';

/// Collects the posts a person has seen and sends them to the server in
/// batches (mobile#541), with the web's rules (app#303): one queue for the
/// whole app, sent at most every [flushEvery], [batchMax] ids per call, and
/// each post sent once per session. The server counts a view once per person
/// too; [_sent] only saves the round trip.
class PostViewTracker {
  PostViewTracker({
    required this.record,
    required this.myUserId,
    this.flushEvery = const Duration(seconds: 5),
  });

  /// A post counts as seen once at least this much of it is on screen…
  static const double visibleRatio = 0.5;

  /// …for this long without leaving.
  static const Duration dwell = Duration(seconds: 1);

  /// Matches the API's cap per request.
  static const int batchMax = 50;

  final Future<List<String>> Function(List<String> postIds) record;
  final String myUserId;
  final Duration flushEvery;

  final _queue = <String>{};
  final _sent = <String>{};
  final _recorded = StreamController<String>.broadcast();
  Timer? _timer;

  /// The ids the server counted, so lists can add the view straight away.
  Stream<String> get recorded => _recorded.stream;

  /// [postId] was on screen long enough. Your own posts are never counted.
  void seen(String postId, {required String authorId}) {
    if (authorId == myUserId || _sent.contains(postId)) return;
    if (!_queue.add(postId)) return;
    _timer ??= Timer(flushEvery, () => unawaited(flush()));
  }

  /// Sends what is queued now, up to [batchMax]; the rest goes next time.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batch = _queue.take(batchMax).toList();
    _queue.removeAll(batch);
    _sent.addAll(batch);
    if (_queue.isNotEmpty) {
      _timer = Timer(flushEvery, () => unawaited(flush()));
    }
    try {
      final counted = await record(batch);
      for (final id in counted) {
        if (!_recorded.isClosed) _recorded.add(id);
      }
    } on Object {
      // A lost view isn't worth retrying or telling anyone about.
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    unawaited(_recorded.close());
  }
}

/// The tracker for whoever is signed in; null when no one is, since views
/// are only counted for signed-in people. A new account gets a new one.
final postViewTrackerProvider = Provider<PostViewTracker?>((ref) {
  final me = ref.watch(authControllerProvider.select((s) => s.user?.id));
  if (me == null) return null;
  final tracker = PostViewTracker(
    record: ref.watch(republicRepositoryProvider).recordViews,
    myUserId: me,
  );
  ref.onDispose(tracker.dispose);
  return tracker;
});

/// Each post the server just counted a view for.
final recordedViewsProvider = StreamProvider<String>(
  (ref) => ref.watch(postViewTrackerProvider)?.recorded ?? const Stream.empty(),
);
