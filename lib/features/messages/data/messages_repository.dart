import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>(
  (ref) => MessagesRepository(ref.watch(apiServiceProvider)),
);

// Both lists belong to one account: they watch the user id, so signing in as
// someone else loads that person's conversations, not the previous ones.
final FutureProvider<List<Conversation>> conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((
  ref,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(messagesRepositoryProvider).getConversations();
});

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<ChatMessage>, String>((
  ref,
  conversationId,
) {
  ref.watch(currentUserIdProvider);
  return ref.watch(messagesRepositoryProvider).getMessages(conversationId);
});

class MessagesRepository {
  const MessagesRepository(this._api);

  final ApiService _api;

  Future<List<Conversation>> getConversations() async {
    final payload = await _api.get(ApiEndpoints.conversations);
    return _dataList(payload)
        .map(Conversation.fromJson)
        .toList(growable: false);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final payload = await _api.get(
      ApiEndpoints.conversationMessages(conversationId),
    );
    return _dataList(payload).map(ChatMessage.fromJson).toList(growable: false);
  }

  Future<void> sendMessage(
    String conversationId,
    String content, {
    String? replyToId,
    List<String> attachmentUrls = const [],
    String? sharedPostId,
  }) async {
    await _api.post(ApiEndpoints.conversationMessages(conversationId), {
      'content': content,
      if (replyToId != null) 'replyToId': replyToId,
      if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
      if (sharedPostId != null) 'sharedPostId': sharedPostId,
    });
  }

  /// Uploads a photo and returns its public URL, to send as an attachment.
  Future<String> uploadPhoto(PickedPhoto photo) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(photo.bytes, filename: photo.name),
    });
    final body = await _api.post(ApiEndpoints.uploadFile, form);
    final file = body is Map ? body['file'] : null;
    final url = (file is Map ? file['url'] : null) ??
        (body is Map ? body['url'] : null);
    if (url is! String) throw const FormatException('No url in the upload');
    return url;
  }

  /// Opens (or finds) the one-to-one chat with a user and returns its id.
  Future<String> startWithUser(String userId) async {
    final body = await _api.post(ApiEndpoints.conversations, {
      'otherUserId': userId,
    });
    return _conversationId(body);
  }

  /// Opens (or finds) the owner-inbox chat for a venue and returns its id.
  Future<String> startVenueInbox(String venueId) async {
    final body = await _api.post(ApiEndpoints.conversationsInbox, {
      'venueId': venueId,
    });
    return _conversationId(body);
  }

  /// [emoji] null removes the user's reaction.
  Future<void> react(
    String conversationId,
    String messageId,
    String? emoji,
  ) async {
    await _api.post(
      ApiEndpoints.conversationReaction(conversationId, messageId),
      {'emoji': emoji},
    );
  }

  Future<void> editMessage(
    String conversationId,
    String messageId,
    String content,
  ) async {
    await _api.patch(
      ApiEndpoints.conversationMessage(conversationId, messageId),
      {'content': content},
    );
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _api.delete(
      ApiEndpoints.conversationMessage(conversationId, messageId),
    );
  }

  Future<void> setMuted(String conversationId, {required bool muted}) async {
    await _api.patch(
      ApiEndpoints.conversationMute(conversationId),
      {'muted': muted},
    );
  }

  Future<void> setPinned(
    String conversationId, {
    required bool pinned,
  }) async {
    await _api.patch(
      ApiEndpoints.conversationPin(conversationId),
      {'pinned': pinned},
    );
  }

  static String _conversationId(Object? body) {
    final data = body is Map ? body['data'] : null;
    final id = data is Map ? data['id'] : null;
    if (id is! String) throw const FormatException('No conversation id');
    return id;
  }

  Future<void> markRead(String conversationId) async {
    await _api.patch(ApiEndpoints.conversationRead(conversationId));
  }

  Future<void> acceptRequest(String conversationId) async {
    await _api.post(ApiEndpoints.conversationAccept(conversationId));
  }

  Future<void> declineRequest(String conversationId) async {
    await _api.post(ApiEndpoints.conversationDecline(conversationId));
  }

  static List<Map<String, dynamic>> _dataList(Object? payload) {
    if (payload is! Map) {
      throw const FormatException('Invalid messages response');
    }
    final data = payload['data'];
    if (data is! List) {
      throw const FormatException('Invalid messages response');
    }
    return data.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      throw const FormatException('Invalid messages response');
    }).toList(growable: false);
  }
}
