import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/messages/data/messages_realtime.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/features/messages/domain/entities/conversation.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnection implements RealtimeConnection {
  final handlers = <String, void Function(Object?)>{};
  final sent = <(String, Object?)>[];
  bool connected = false;
  bool disposed = false;

  @override
  void on(String event, void Function(Object? data) handler) =>
      handlers[event] = handler;

  @override
  void emit(String event, Object? data) => sent.add((event, data));

  @override
  void connect() => connected = true;

  @override
  void dispose() => disposed = true;

  void receive(String event, [Object? data]) => handlers[event]?.call(data);
}

void main() {
  late _FakeConnection connection;
  late RealtimeService service;

  setUp(() {
    connection = _FakeConnection();
    service = RealtimeService(
      url: 'http://localhost:6002',
      getTicket: () async => 'ticket',
      factory: (_, __) => connection,
    );
  });

  test('connects once and listens for every server event', () {
    service
      ..start()
      ..start();

    expect(connection.connected, isTrue);
    expect(
      connection.handlers.keys,
      containsAll(RealtimeEvents.all),
    );
  });

  test('turns socket messages into events with a map payload', () async {
    service.start();
    final next = service.events.first;

    connection.receive(RealtimeEvents.newMessage, {
      'conversationId': 'c1',
      'content': 'hi',
    });

    final event = await next;
    expect(event.name, RealtimeEvents.newMessage);
    expect(event.conversationId, 'c1');
    expect(event.payload['content'], 'hi');
  });

  test('a payload that is not a map becomes an empty one', () async {
    service.start();
    final next = service.events.first;

    connection.receive(RealtimeEvents.dataInvalidate, 'oops');

    final event = await next;
    expect(event.payload, isEmpty);
    expect(event.conversationId, isNull);
  });

  test('emits client events and closes cleanly', () {
    service
      ..start()
      ..emit(RealtimeEvents.typing, {'conversationId': 'c1'});

    expect(connection.sent.single.$1, RealtimeEvents.typing);
    expect(connection.sent.single.$2, {'conversationId': 'c1'});

    service.stop();
    expect(connection.disposed, isTrue);
  });

  group('messagesRealtimeProvider', () {
    test('a new message reloads the list and that chat', () async {
      service.start();
      var listLoads = 0;
      final chatLoads = <String>[];
      final container = ProviderContainer(
        overrides: [
          realtimeServiceProvider.overrideWithValue(service),
          conversationsProvider.overrideWith((ref) async {
            listLoads++;
            return const <Conversation>[];
          }),
          chatMessagesProvider.overrideWith((ref, id) async {
            chatLoads.add(id);
            return const [];
          }),
        ],
      );
      addTearDown(container.dispose);

      container
        ..listen(messagesRealtimeProvider, (_, __) {})
        ..listen(conversationsProvider, (_, __) {})
        ..listen(chatMessagesProvider('c1'), (_, __) {});
      await container.read(conversationsProvider.future);
      await container.read(chatMessagesProvider('c1').future);
      expect(listLoads, 1);
      expect(chatLoads, ['c1']);

      connection.receive(RealtimeEvents.newMessage, {'conversationId': 'c1'});
      await Future<void>.delayed(Duration.zero);
      await container.read(conversationsProvider.future);
      await container.read(chatMessagesProvider('c1').future);

      expect(listLoads, 2);
      expect(chatLoads, ['c1', 'c1']);
    });

    test('typing shows for a few seconds, then clears', () async {
      service.start();
      final container = ProviderContainer(
        overrides: [realtimeServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      container.listen(messagesRealtimeProvider, (_, __) {});

      connection.receive(RealtimeEvents.typing, {'conversationId': 'c1'});
      await Future<void>.delayed(Duration.zero);

      expect(container.read(typingProvider), {'c1'});

      container.read(typingProvider.notifier).mark('c2');
      expect(container.read(typingProvider), {'c1', 'c2'});
    });
  });
}
