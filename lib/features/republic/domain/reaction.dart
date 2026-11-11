import 'package:equatable/equatable.dart';

/// How someone can react to a post, in the order the picker shows them.
enum ReactionType {
  like('👍'),
  love('❤️'),
  haha('😂'),
  wow('😮'),
  sad('😢'),
  angry('😠');

  const ReactionType(this.emoji);

  final String emoji;

  /// The reaction the API names [value], or null.
  static ReactionType? tryParse(Object? value) {
    for (final r in values) {
      if (r.name == value) return r;
    }
    return null;
  }
}

/// How many people chose one reaction on a post.
class ReactionCount extends Equatable {
  const ReactionCount(this.type, this.count);

  final ReactionType type;
  final int count;

  @override
  List<Object?> get props => [type, count];

  /// [counts] after someone's reaction changes from [from] to [to] (either
  /// null for none): one comes off [from] and one goes on [to]. Types left
  /// at zero drop out, and the list stays ordered most chosen first.
  static List<ReactionCount> change(
    List<ReactionCount> counts, {
    required ReactionType? from,
    required ReactionType? to,
  }) {
    if (from == to) return counts;
    final byType = {for (final c in counts) c.type: c.count};
    if (from != null) byType[from] = (byType[from] ?? 0) - 1;
    if (to != null) byType[to] = (byType[to] ?? 0) + 1;
    final next = [
      for (final e in byType.entries)
        if (e.value > 0) ReactionCount(e.key, e.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
    return next;
  }

  /// Reads the list the API sends; unknown types are skipped.
  static List<ReactionCount> parseList(Object? json) => [
        for (final r in json as List? ?? const [])
          if (r is Map && ReactionType.tryParse(r['type']) != null)
            ReactionCount(
              ReactionType.tryParse(r['type'])!,
              (r['count'] as num?)?.toInt() ?? 0,
            ),
      ];
}
