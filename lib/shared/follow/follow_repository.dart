import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_template/shared/follow/person.dart';

/// Following people: who you follow and who follows them.
class FollowRepository {
  FollowRepository(this._api);

  final ApiService _api;

  Future<FollowStatus> status(String userId) async {
    final status = await _api.get(ApiEndpoints.followStatus(userId));
    Object? counts;
    try {
      counts = await _api.get(ApiEndpoints.followCounts(userId));
    } on AppException {
      // A private account keeps its numbers to its followers.
      counts = null;
    }
    return FollowStatus.fromJson(
      status is Map ? status['data'] : null,
      counts is Map ? counts['data'] : null,
    );
  }

  /// Follows [userId]: instant for a public account, a request for a private
  /// one. Returns which of the two happened.
  Future<FollowState> follow(String userId) async {
    final body = await _api.post(ApiEndpoints.follows, {'targetId': userId});
    final data = body is Map ? body['data'] : null;
    return FollowState.parse(data is Map ? data['status'] : null);
  }

  /// One page (up to 50) of [list] for [userId]; requests are always yours.
  Future<List<Person>> people(String userId, PeopleList list) async {
    final path = switch (list) {
      PeopleList.followers => ApiEndpoints.followers(userId),
      PeopleList.following => ApiEndpoints.following(userId),
      PeopleList.requests => ApiEndpoints.followRequests,
    };
    final body = await _api.get(path, query: {'limit': 50});
    final data = body is Map ? body['data'] : null;
    final rows = data is Map ? data['data'] : null;
    if (rows is! List) return const [];
    return [
      for (final row in rows)
        if (row is Map) Person.fromJson(row.cast<String, dynamic>()),
    ];
  }

  /// Lets [requesterId] follow you, or turns them down.
  Future<void> answerRequest(String requesterId, {required bool accept}) async {
    await _api.post(
      accept
          ? ApiEndpoints.followAccept(requesterId)
          : ApiEndpoints.followDecline(requesterId),
      const {},
    );
  }

  /// Unfollows, or withdraws a request that has not been answered.
  Future<void> unfollow(String userId) async {
    await _api.delete(ApiEndpoints.followTarget(userId));
  }
}

final followRepositoryProvider = Provider<FollowRepository>(
  (ref) => FollowRepository(ref.watch(apiServiceProvider)),
);

/// Your follow of one person. Both changes throw when the server refuses,
/// leaving it as it was.
class FollowController extends AsyncNotifier<FollowStatus> {
  FollowController(this.userId);

  final String userId;

  @override
  Future<FollowStatus> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(followRepositoryProvider).status(userId);
  }

  Future<void> follow() async {
    final next = await ref.read(followRepositoryProvider).follow(userId);
    state = AsyncData((state.value ?? const FollowStatus()).after(next));
  }

  Future<void> unfollow() async {
    await ref.read(followRepositoryProvider).unfollow(userId);
    state = AsyncData(
      (state.value ?? const FollowStatus()).after(FollowState.none),
    );
  }
}

/// One of a person's lists. Answering a request drops it from the list.
class PeopleController extends AsyncNotifier<List<Person>> {
  PeopleController(this.key);

  final ({String userId, PeopleList list}) key;

  @override
  Future<List<Person>> build() {
    ref.watch(currentUserIdProvider);
    return ref.read(followRepositoryProvider).people(key.userId, key.list);
  }

  /// Accepts or declines the request from [requesterId]; throws when the
  /// server refuses, leaving the list as it was.
  Future<void> answer(String requesterId, {required bool accept}) async {
    await ref
        .read(followRepositoryProvider)
        .answerRequest(requesterId, accept: accept);
    state = AsyncData([
      for (final p in state.value ?? const <Person>[])
        if (p.id != requesterId) p,
    ]);
  }
}

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final peopleProvider = AsyncNotifierProvider.autoDispose
    .family<PeopleController, List<Person>, ({String userId, PeopleList list})>(
  PeopleController.new,
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final followProvider = AsyncNotifierProvider.autoDispose
    .family<FollowController, FollowStatus, String>(FollowController.new);
