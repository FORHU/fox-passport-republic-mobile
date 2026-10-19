import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';

/// How long "typing…" lasts after the last signal from the other person.
const typingHold = Duration(seconds: 4);

/// Conversation ids where someone is typing right now.
class TypingNotifier extends Notifier<Set<String>> {
  final _timers = <String, Timer>{};

  @override
  Set<String> build() {
    // Typing signals belong to one account's chats.
    ref.watch(currentUserIdProvider);
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  void mark(String conversationId) {
    _timers[conversationId]?.cancel();
    _timers[conversationId] = Timer(typingHold, () {
      _timers.remove(conversationId);
      state = {...state}..remove(conversationId);
    });
    if (!state.contains(conversationId)) {
      state = {...state, conversationId};
    }
  }
}

final typingProvider = NotifierProvider<TypingNotifier, Set<String>>(
  TypingNotifier.new,
);

/// Turns socket events into refreshes: a new, edited, deleted or reacted-to
/// message reloads that chat and the conversation list, presence reloads the
/// list (online dots), and typing is kept in [typingProvider].
///
/// Watch it once, high in the tree, while signed in.
final messagesRealtimeProvider = Provider<void>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  if (service == null) return;

  final subscription = service.events.listen((event) {
    switch (event.name) {
      case RealtimeEvents.newMessage:
      case RealtimeEvents.messageEdited:
      case RealtimeEvents.messageDeleted:
      case RealtimeEvents.messageReaction:
      case RealtimeEvents.messagePinned:
      case RealtimeEvents.readReceipt:
        ref.invalidate(conversationsProvider);
        final id = event.conversationId;
        if (id == null) {
          // Unknown conversation: reload every open chat.
          ref.invalidate(chatMessagesProvider);
        } else {
          ref.invalidate(chatMessagesProvider(id));
        }
      case RealtimeEvents.presenceUpdate:
      case RealtimeEvents.groupRemoved:
        ref.invalidate(conversationsProvider);
      case RealtimeEvents.typing:
        final id = event.conversationId;
        if (id != null) ref.read(typingProvider.notifier).mark(id);
    }
  });
  ref.onDispose(subscription.cancel);
});
