/// Where you stand with another person.
enum FollowState {
  none,

  /// You asked and a private account has not answered yet.
  pending,
  following;

  static FollowState parse(Object? raw) => switch (raw) {
        'accepted' => following,
        'pending' => pending,
        _ => none,
      };
}

/// Your follow of one person, with how many follow them when that is visible.
class FollowStatus {
  const FollowStatus({this.state = FollowState.none, this.followers});

  factory FollowStatus.fromJson(Object? status, Object? counts) {
    final s = status is Map ? status : const <String, dynamic>{};
    // Only an outgoing follow is yours to undo; incoming is them following you.
    final mine = s['direction'] == 'outgoing';
    final followers = counts is Map ? counts['followers'] : null;
    return FollowStatus(
      state: mine ? FollowState.parse(s['status']) : FollowState.none,
      followers: followers is num ? followers.toInt() : null,
    );
  }

  final FollowState state;

  /// Null when the API keeps the numbers private.
  final int? followers;

  FollowStatus after(FollowState next) {
    final count = followers;
    var delta = 0;
    if (next == FollowState.following && state != FollowState.following) {
      delta = 1;
    } else if (next != FollowState.following &&
        state == FollowState.following) {
      delta = -1;
    }
    return FollowStatus(
      state: next,
      followers: count == null ? null : count + delta,
    );
  }
}
