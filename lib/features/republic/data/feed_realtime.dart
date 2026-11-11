import 'package:flutter_riverpod/flutter_riverpod.dart';
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
