import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// Someone the signed-in user has blocked.
class BlockedUser extends Equatable {
  const BlockedUser({
    required this.id,
    required this.name,
    this.username = '',
    this.imageUrl,
  });

  /// Reads one row of `GET /blocks`; null when it has no id.
  static BlockedUser? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    String? text(String key) {
      final v = row[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return BlockedUser(
      id: '${row['id']}',
      name: text('name') ?? text('username') ?? '',
      username: text('username') ?? '',
      imageUrl: text('imgId'),
    );
  }

  final String id;
  final String name;
  final String username;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, username, imageUrl];
}

class BlocksRepository {
  BlocksRepository(this._api);

  final ApiService _api;

  Future<List<BlockedUser>> list() async {
    final body = await _api.get(ApiEndpoints.blocks, query: {'limit': 50});
    // `{ data: { data: [...], total, page } }`; a bare list is read as is.
    final outer = body is Map ? body['data'] : null;
    final rows = outer is Map ? outer['data'] : outer;
    if (rows is! List) {
      throw const FormatException('Blocked users response is not a list');
    }
    return [
      for (final row in rows)
        if (BlockedUser.tryParse(row) case final user?) user,
    ];
  }

  Future<void> unblock(String userId) async {
    await _api.delete(ApiEndpoints.unblock(userId));
  }
}

final blocksRepositoryProvider = Provider<BlocksRepository>(
  (ref) => BlocksRepository(ref.watch(apiServiceProvider)),
);

/// The blocked list. Watches the signed-in user so another account never
/// sees the previous one's.
final FutureProvider<List<BlockedUser>> blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(blocksRepositoryProvider).list();
});
