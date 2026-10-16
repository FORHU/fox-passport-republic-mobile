import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/reviews/review.dart';
import 'package:flutter_template/shared/reviews/reviews_repository.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// What people said about a venue or event: the stars at a glance, the
/// newest few reviews, and the rest behind "See all".
class ReviewsSection extends ConsumerWidget {
  const ReviewsSection({required this.listingId, super.key});

  final String listingId;

  static const _preview = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(listingReviewsProvider(listingId));

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: async.when(
        loading: () => const SizedBox(
          height: 48,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Row(
          children: [
            Expanded(
              child: Text(
                l10n.reviewsLoadFailed,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(listingReviewsProvider(listingId)),
              child: Text(l10n.retry),
            ),
          ],
        ),
        data: (summary) {
          if (summary.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reviewsTitle,
                  style: AppTypography.display(size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.reviewsNone,
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.reviewsTitle, style: AppTypography.display(size: 18)),
              const SizedBox(height: 12),
              _Overview(summary: summary),
              const SizedBox(height: 16),
              for (final r in summary.reviews.take(_preview)) ReviewTile(r),
              if (summary.count > _preview)
                TextButton(
                  onPressed: () => _showAll(context, summary),
                  child: Text(l10n.reviewsSeeAll(summary.count)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showAll(BuildContext context, ReviewSummary summary) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                context.l10n.reviewsTitle,
                style: AppTypography.display(size: 20),
              ),
              const SizedBox(height: 12),
              _Overview(summary: summary),
              const SizedBox(height: 16),
              for (final r in summary.reviews) ReviewTile(r),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Column(
          children: [
            Text(
              summary.average.toStringAsFixed(1),
              style: AppTypography.display(size: 36),
            ),
            Stars(rating: summary.average.round(), size: 16),
            const SizedBox(height: 4),
            Text(
              l10n.reviewsCount(summary.count),
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (final star in const [5, 4, 3, 2, 1])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        child: Text(
                          '$star',
                          style: AppTypography.body(
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.brPill,
                          child: LinearProgressIndicator(
                            value: (summary.percentByStar[star] ?? 0) / 100,
                            minHeight: 6,
                            color: AppColors.accent,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One review: who, when, the stars, what they wrote and any host replies.
class ReviewTile extends StatelessWidget {
  const ReviewTile(this.review, {super.key});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final when = review.createdAt == null
        ? null
        : DateFormat.yMMMd(locale).format(review.createdAt!);
    final name = review.author.isEmpty ? '?' : review.author;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: review.authorImageUrl == null
                      ? ColoredBox(
                          color: AppColors.surface,
                          child: Center(
                            child: Text(
                              name.characters.first.toUpperCase(),
                              style: AppTypography.display(size: 15),
                            ),
                          ),
                        )
                      : NetworkImageBox(
                          url: review.authorImageUrl!,
                          width: 36,
                          height: 36,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.body(weight: FontWeight.w600),
                    ),
                    if (when != null)
                      Text(
                        when,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Stars(rating: review.rating),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: AppTypography.body()),
          ],
          for (final reply in review.replies)
            Container(
              margin: const EdgeInsets.only(top: 8, left: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reply.author.isNotEmpty)
                    Text(
                      reply.author,
                      style: AppTypography.label(),
                    ),
                  Text(reply.text, style: AppTypography.body(size: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Five stars with [rating] of them filled.
class Stars extends StatelessWidget {
  const Stars({required this.rating, this.size = 14, super.key});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= rating ? AppColors.accent : AppColors.textMuted,
          ),
      ],
    );
  }
}
