import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';

/// A post's comment count as the server now has it.
typedef PostCommentsCount = ({String postId, int commentsCount});

/// Reads a `post:comments_count` payload, or null when it is not one.
PostCommentsCount? parsePostCommentsCount(Map<String, dynamic> payload) {
  final id = payload['postId'];
  final count = payload['commentsCount'];
  if (id is! String || count is! num) return null;
  return (postId: id, commentsCount: count.toInt());
}

/// Every comment count change the server announces, for any post. Silent
/// while signed out or on the mock backend, which have no socket.
final postCommentsCountProvider = StreamProvider<PostCommentsCount>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  if (service == null) return const Stream.empty();
  return service.events
      .where((e) => e.name == RealtimeEvents.postCommentsCount)
      .map((e) => parsePostCommentsCount(e.payload))
      .where((c) => c != null)
      .cast<PostCommentsCount>();
});

/// A public post was just created (`feed:new`). A new object per event, so
/// two posts in a row on the same tab are two changes, not one.
class FeedNewEvent {
  FeedNewEvent(this.tab);

  /// The tab it was posted on, or null when the server did not say.
  final String? tab;
}

/// Every new public post the server announces (app#308). Silent while signed
/// out or on the mock backend, which have no socket.
final feedNewProvider = StreamProvider<FeedNewEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  if (service == null) return const Stream.empty();
  return service.events
      .where((e) => e.name == RealtimeEvents.feedNew)
      .map((e) => FeedNewEvent(_tabOf(e.payload)));
});

String? _tabOf(Map<String, dynamic> payload) {
  final tab = payload['tab'];
  return tab is String ? tab : null;
}

/// How often the feed asks for new posts when no socket will tell it: every
/// minute while signed out; null (never) while signed in, when `feed:new`
/// arrives over the socket instead.
final feedNewPollIntervalProvider = Provider<Duration?>((ref) {
  final signedIn = ref.watch(
    authControllerProvider.select((s) => s.isAuthenticated),
  );
  return signedIn ? null : const Duration(minutes: 1);
});
