import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/chat_message.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

/// Counts the loads, so a reload for another account can be told from a cache.
class _CountingMessages extends MessagesRepository {
  _CountingMessages() : super(_MockApi());

  int conversationLoads = 0;
  int messageLoads = 0;

  @override
  Future<List<Conversation>> getConversations() async {
    conversationLoads++;
    return const [];
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    messageLoads++;
    return const [];
  }
}

class _TestAuth extends AuthController {
  @override
  AuthState build() => const AuthState();

  void signInAs(String? id) => state = id == null
      ? const AuthState()
      : AuthState(user: UserEntity(id: id, email: '$id@x.com', name: id));
}

void main() {
  group('messages belong to one account', () {
    late ProviderContainer container;
    late _CountingMessages repo;

    setUp(() {
      repo = _CountingMessages();
      container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_TestAuth.new),
          messagesRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      // Keep them alive like the open app does, so only the user id can reset.
      container
        ..listen(conversationsProvider, (_, __) {})
        ..listen(chatMessagesProvider('c1'), (_, __) {});
    });

    void signInAs(String? id) =>
        (container.read(authControllerProvider.notifier) as _TestAuth)
            .signInAs(id);

    test('conversations are loaded again for the next account', () async {
      signInAs('a');
      await container.read(conversationsProvider.future);
      final loadedForA = repo.conversationLoads;

      signInAs(null);
      signInAs('b');
      await container.read(conversationsProvider.future);
      expect(repo.conversationLoads, greaterThan(loadedForA));
    });

    test('an open chat is loaded again for the next account', () async {
      signInAs('a');
      await container.read(chatMessagesProvider('c1').future);
      final loadedForA = repo.messageLoads;

      signInAs('b');
      await container.read(chatMessagesProvider('c1').future);
      expect(repo.messageLoads, greaterThan(loadedForA));
    });

    test('the same account keeps what it loaded', () async {
      signInAs('a');
      await container.read(conversationsProvider.future);
      final loadedForA = repo.conversationLoads;

      await container.read(conversationsProvider.future);
      expect(repo.conversationLoads, loadedForA);
    });
  });

  group('clearSession', () {
    test('forgets onboarding but keeps the device flags', () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final storage = StorageService(await SharedPreferences.getInstance());
      await storage.setOnboardingSeen();
      await storage.setWelcomeSeen();
      await storage.setLocationPromptSeen();

      await storage.clearSession();

      expect(storage.onboardingSeen, isFalse);
      expect(storage.welcomeSeen, isTrue);
      expect(storage.locationPromptSeen, isTrue);
    });
  });
}
