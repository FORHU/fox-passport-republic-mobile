import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';

String? _text(Object? v) =>
    v is String && v.trim().isNotEmpty ? v.trim() : null;

/// The post types the feed can show, as the API names them.
abstract final class PostTypes {
  static const venueSpotlight = 'venue_spotlight';
  static const gearOffering = 'gear_offering';
  static const serviceOffering = 'service_offering';
  static const eventAnnouncement = 'event_announcement';
  static const partnerAnnouncement = 'partner_announcement';
  static const reviewShare = 'review_share';
  static const poll = 'poll';

  /// The post's key for the listing it points at, and what kind of catalog
  /// row that is. Null when the type points at nothing.
  static ({String key, CatalogKind kind})? listingFor(String type) =>
      switch (type) {
        venueSpotlight => (key: 'venue', kind: CatalogKind.venues),
        gearOffering => (key: 'asset', kind: CatalogKind.gear),
        serviceOffering => (key: 'service', kind: CatalogKind.services),
        eventAnnouncement => (key: 'event', kind: CatalogKind.events),
        _ => null,
      };
}

/// One choice in a poll and who picked it.
class PollOption extends Equatable {
  const PollOption({
    required this.id,
    required this.label,
    required this.votes,
    this.voterIds = const [],
  });

  final String id;
  final String label;
  final int votes;
  final List<String> voterIds;

  @override
  List<Object?> get props => [id, label, votes, voterIds];
}

/// A poll on a post. Single choice: voting for another option moves the
/// vote, voting for your own takes it back.
class PostPoll extends Equatable {
  const PostPoll({required this.id, required this.options});

  /// Reads the poll the feed and the vote call send; null when it has no
  /// options.
  static PostPoll? tryParse(Object? json) {
    if (json is! Map) return null;
    final rows = json['options'];
    if (rows is! List || rows.isEmpty) return null;
    final options = <PollOption>[
      for (final r in rows)
        if (r is Map && r['id'] != null)
          PollOption(
            id: '${r['id']}',
            label: _text(r['label']) ?? '',
            votes: (r['votesCount'] as num?)?.toInt() ?? 0,
            voterIds: [
              for (final v in r['votes'] as List? ?? const [])
                if (v is Map && v['userId'] != null) '${v['userId']}',
            ],
          ),
    ];
    return options.isEmpty
        ? null
        : PostPoll(id: '${json['id']}', options: options);
  }

  final String id;
  final List<PollOption> options;

  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);

  /// The option [userId] picked, if any.
  String? pickedBy(String? userId) {
    if (userId == null) return null;
    for (final o in options) {
      if (o.voterIds.contains(userId)) return o.id;
    }
    return null;
  }

  @override
  List<Object?> get props => [id, options];
}

/// The review a "review share" post quotes.
class PostReview extends Equatable {
  const PostReview({required this.rating, this.comment});

  static PostReview? tryParse(Object? json) {
    if (json is! Map) return null;
    final rating = (json['rating'] as num?)?.toInt();
    if (rating == null) return null;
    return PostReview(
      rating: rating.clamp(0, 5),
      comment: _text(json['comment']),
    );
  }

  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [rating, comment];
}

/// A Venue Stamp a post was made with.
class PostStamp extends Equatable {
  const PostStamp({required this.eventName, this.venueName, this.city});

  static PostStamp? tryParse(Object? json) {
    if (json is! Map) return null;
    final venue = json['venue'];
    final name =
        _text(venue is Map ? venue['name'] : null) ?? _text(json['eventName']);
    if (name == null) return null;
    return PostStamp(
      eventName: name,
      venueName: venue is Map ? _text(venue['name']) : null,
      city: venue is Map ? _text(venue['city']) : null,
    );
  }

  final String eventName;
  final String? venueName;
  final String? city;

  @override
  List<Object?> get props => [eventName, venueName, city];
}

/// The post a repost quotes.
class OriginalPost extends Equatable {
  const OriginalPost({
    required this.id,
    required this.authorName,
    required this.content,
    this.imageUrl,
  });

  static OriginalPost? tryParse(Object? json) {
    if (json is! Map || json['id'] == null) return null;
    final author = json['author'];
    final media = json['mediaUrls'];
    return OriginalPost(
      id: '${json['id']}',
      authorName: author is Map
          ? _text(author['name']) ?? _text(author['username']) ?? ''
          : '',
      content: (json['content'] ?? '').toString().trim(),
      imageUrl: media is List && media.isNotEmpty ? _text(media.first) : null,
    );
  }

  final String id;
  final String authorName;
  final String content;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, authorName, content, imageUrl];
}

/// Reads the listing a marketplace post points at, as a catalog row, so it
/// opens like one from Search. Null for other types or a missing row.
CatalogItem? listingOf(String type, Map<String, dynamic> json) {
  final target = PostTypes.listingFor(type);
  if (target == null) return null;
  final row = json[target.key];
  if (row is! Map) return null;
  return CatalogRepository.parse(target.kind, row.cast<String, dynamic>());
}
