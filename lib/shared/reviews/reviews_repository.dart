import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/reviews/review.dart';

/// Reads what people said about a venue or event, and writes your own.
class ReviewsRepository {
  ReviewsRepository(this._api);

  final ApiService _api;

  Future<ReviewSummary> forListing(String listingId) async {
    final body = await _api.get(
      ApiEndpoints.reviewsOfListing(listingId),
      query: {'includeReplies': 'true'},
    );
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) return ReviewSummary.empty;
    return ReviewSummary.fromJson(data.cast<String, dynamic>());
  }

  /// Reviews a booking you went to. The server works out the venue or event
  /// from the booking and refuses a second review of the same one.
  Future<void> create({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    await _api.post(ApiEndpoints.reviewsCreate, {
      'bookingId': bookingId,
      'rating': rating,
      if (comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>(
  (ref) => ReviewsRepository(ref.watch(apiServiceProvider)),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final listingReviewsProvider =
    FutureProvider.autoDispose.family<ReviewSummary, String>(
  (ref, listingId) =>
      ref.watch(reviewsRepositoryProvider).forListing(listingId),
);
