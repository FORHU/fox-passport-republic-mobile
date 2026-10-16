import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Event names the API's socket gateway emits and accepts. They are the
/// contract with the server (`socket.constants.ts`); a typo fails silently.
class RealtimeEvents {
  RealtimeEvents._();

  static const newNotification = 'new_notification';
  static const dataInvalidate = 'data:invalidate';
  static const newMessage = 'new_message';
  static const messageDeleted = 'message_deleted';
  static const messageReaction = 'message_reaction';
  static const messageEdited = 'message_edited';
  static const messagePinned = 'message:pinned';
  static const readReceipt = 'read:receipt';
  static const typing = 'typing';
  static const presenceUpdate = 'presence:update';
  static const groupRemoved = 'group:removed';

  static const List<String> all = [
    newNotification,
    dataInvalidate,
    newMessage,
    messageDeleted,
    messageReaction,
    messageEdited,
    messagePinned,
    readReceipt,
    typing,
    presenceUpdate,
    groupRemoved,
  ];
}

/// One message from the server.
class RealtimeEvent {
  const RealtimeEvent(this.name, this.payload);

  final String name;

  /// The JSON object the server sent, or an empty map when it sent none.
  final Map<String, dynamic> payload;

  /// The conversation the event is about, when it names one.
  String? get conversationId {
    final id = payload['conversationId'];
    return id is String ? id : null;
  }
}

/// The transport under [RealtimeService]. Kept as an interface so tests can
/// drive the service without a network.
abstract class RealtimeConnection {
  void on(String event, void Function(Object? data) handler);
  void emit(String event, Object? data);
  void connect();
  void dispose();
}

typedef RealtimeConnectionFactory = RealtimeConnection Function(
  String url,
  Future<String?> Function() getTicket,
);

/// socket.io, with the handshake ticket asked for again on every attempt:
/// tickets are single use, so one captured at start would fail every
/// reconnection after a dropped network.
class SocketIoConnection implements RealtimeConnection {
  SocketIoConnection(String url, Future<String?> Function() getTicket)
      : _socket = io.io(
          url,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .enableReconnection()
              .setAuthFn((callback) {
                // Hand back nothing rather than hang: the server rejects
                // the handshake and the next retry asks for a new ticket.
                unawaited(
                  getTicket()
                      .then(
                        (ticket) => callback(
                          ticket == null ? {} : {'ticket': ticket},
                        ),
                      )
                      .catchError((Object _) => callback({})),
                );
              })
              .build(),
        );

  final io.Socket _socket;

  @override
  void on(String event, void Function(Object? data) handler) =>
      _socket.on(event, handler);

  @override
  void emit(String event, Object? data) => _socket.emit(event, data);

  @override
  void connect() => _socket.connect();

  @override
  void dispose() {
    _socket
      ..clearListeners()
      ..dispose();
  }
}

/// A live connection to the API, exposed as a stream of [RealtimeEvent]s.
class RealtimeService {
  RealtimeService({
    required this.url,
    required this.getTicket,
    RealtimeConnectionFactory? factory,
  }) : _factory = factory ?? SocketIoConnection.new;

  final String url;
  final Future<String?> Function() getTicket;
  final RealtimeConnectionFactory _factory;

  final _events = StreamController<RealtimeEvent>.broadcast();
  RealtimeConnection? _connection;

  Stream<RealtimeEvent> get events => _events.stream;

  void start() {
    if (_connection != null) return;
    final connection = _factory(url, getTicket);
    for (final name in RealtimeEvents.all) {
      connection.on(name, (data) {
        if (_events.isClosed) return;
        _events.add(
          RealtimeEvent(
            name,
            data is Map ? Map<String, dynamic>.from(data) : const {},
          ),
        );
      });
    }
    _connection = connection..connect();
  }

  /// Sends a client event, such as `typing`. Ignored until started.
  void emit(String event, Map<String, dynamic> data) =>
      _connection?.emit(event, data);

  void stop() {
    _connection?.dispose();
    _connection = null;
    if (!_events.isClosed) unawaited(_events.close());
  }
}

/// The signed-in user's connection, or null when signed out or running
/// against the mock backend (which has no socket).
final realtimeServiceProvider = Provider<RealtimeService?>((ref) {
  final signedIn = ref.watch(
    authControllerProvider.select((s) => s.isAuthenticated),
  );
  if (!signedIn || AppConfig.instance.useMock) return null;

  final api = ref.watch(apiServiceProvider);
  final service = RealtimeService(
    url: Uri.parse(AppConfig.instance.baseUrl).origin,
    getTicket: () async {
      final body = await api.post(ApiEndpoints.socketTicket);
      final data = body is Map ? body['data'] : null;
      final ticket = data is Map ? data['ticket'] : null;
      return ticket is String ? ticket : null;
    },
  )..start();
  ref.onDispose(service.stop);
  return service;
});
