import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/feed_realtime.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/shared/realtime/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _FakeConnection implements RealtimeConnection {
  final handlers = <String, void Function(Object?)>{};

  @override
  void on(String event, void Function(Object? data) handler) =>
      handlers[event] = handler;

  @override
  void emit(String event, Object? data) {}

  @override
  void connect() {}

  @override
  void dispose() {}

  void receive(String event, Object? data) => handlers[event]?.call(data);
}

Map<String, dynamic> _post(String id, int comments) => {
      'id': id,
      'content': 'post $id',
      'tab': 'community',
      'commentsCount': comments,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': 'u', 'name': 'Maria'},
    };

void main() {
  test('reads a comment count payload, and ignores a malformed one', () {
    expect(
      parsePostCommentsCount({'postId': 'a', 'commentsCount': 3}),
      (postId: 'a', commentsCount: 3),
    );
    expect(parsePostCommentsCount({'postId': 'a'}), isNull);
    expect(parsePostCommentsCount({'commentsCount': 1}), isNull);
  });

  test('a comment count from the socket updates that post in every feed',
      () async {
    final api = _MockApi();
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'data': [_post('a', 0), _post('b', 4)],
        'nextCursor': null,
      },
    );
    final connection = _FakeConnection();
    final service = RealtimeService(
      url: 'http://localhost:6002',
      getTicket: () async => 'ticket',
      factory: (_, __) => connection,
    )..start();
    addTearDown(service.stop);

    final container = ProviderContainer(
      overrides: [
        republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
        realtimeServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);
    for (final tab in [null, 'community']) {
      final sub = container.listen(feedControllerProvider(tab), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(tab).future);
    }

    connection.receive(
      RealtimeEvents.postCommentsCount,
      {'postId': 'a', 'commentsCount': 1},
    );
    await Future<void>.delayed(Duration.zero);

    for (final tab in [null, 'community']) {
      final counts = {
        for (final p
            in container.read(feedControllerProvider(tab)).requireValue.posts)
          p.id: p.commentsCount,
      };
      expect(counts, {'a': 1, 'b': 4});
    }
  });
}
