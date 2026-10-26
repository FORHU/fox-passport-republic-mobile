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
class ReactionCount {
  const ReactionCount(this.type, this.count);

  final ReactionType type;
  final int count;

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
