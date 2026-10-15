import 'package:equatable/equatable.dart';

/// A host's answer under a review.
class ReviewReply extends Equatable {
  const ReviewReply({required this.author, required this.text});

  final String author;
  final String text;

  @override
  List<Object?> get props => [author, text];
}

/// One review of a venue or event, as `GET /reviews/listing/:id` returns it.
class Review extends Equatable {
  const Review({
    required this.id,
    required this.author,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.authorImageUrl,
    this.replies = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? (json['user'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return Review(
      id: '${json['id']}',
      author: text(user['name']) ?? '',
      authorImageUrl: text(user['imgId']),
      rating: ((json['rating'] as num?) ?? 0).round().clamp(0, 5),
      comment: text(json['comment']),
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      replies: [
        for (final r in json['replies'] as List? ?? const [])
          if (r is Map && text(r['text']) != null)
            ReviewReply(
              author: text((r['user'] as Map?)?['name']) ?? '',
              text: text(r['text'])!,
            ),
      ],
    );
  }

  final String id;
  final String author;
  final String? authorImageUrl;

  /// Whole stars, 0 to 5.
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final List<ReviewReply> replies;

  @override
  List<Object?> get props =>
      [id, author, authorImageUrl, rating, comment, createdAt, replies];
}

/// The reviews of one listing and how its stars are spread.
class ReviewSummary extends Equatable {
  const ReviewSummary({required this.reviews, required this.percentByStar});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final percent = <int, int>{};
    final raw = json['ratingDistribution'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final star = int.tryParse('${e.key}');
        final value = int.tryParse('${e.value}'.replaceAll('%', ''));
        if (star != null && value != null) percent[star] = value;
      }
    }
    return ReviewSummary(
      reviews: [
        for (final r in json['reviews'] as List? ?? const [])
          if (r is Map) Review.fromJson(r.cast<String, dynamic>()),
      ],
      percentByStar: percent,
    );
  }

  static const empty = ReviewSummary(reviews: [], percentByStar: {});

  final List<Review> reviews;

  /// Share of reviews at each star, 0 to 100, over all of them.
  final Map<int, int> percentByStar;

  bool get isEmpty => reviews.isEmpty;
  int get count => reviews.length;

  /// Mean stars of the reviews loaded, or 0 with none.
  double get average => reviews.isEmpty
      ? 0
      : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length;

  @override
  List<Object?> get props => [reviews, percentByStar];
}
