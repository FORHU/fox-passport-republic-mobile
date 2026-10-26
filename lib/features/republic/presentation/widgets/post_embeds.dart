import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/post_extras.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// What a post carries besides its words and photos: a poll, a stamp, a
/// quoted review, the listing it advertises, a partner offer, or the post it
/// reposts. Draws nothing for a plain story.
class PostEmbeds extends ConsumerWidget {
  const PostEmbeds({
    required this.post,
    this.myUserId,
    this.onVote,
    this.onOpenListing,
    this.onMessage,
    super.key,
  });

  final Post post;

  /// Who is looking, to show which poll option is theirs.
  final String? myUserId;
  final ValueChanged<String>? onVote;
  final VoidCallback? onOpenListing;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[
      if (post.stamp != null) _StampChip(stamp: post.stamp!),
      if (post.poll != null)
        _PollView(poll: post.poll!, myUserId: myUserId, onVote: onVote),
      if (post.review != null) _ReviewCard(review: post.review!),
      if (post.listing != null)
        _ListingCard(
          item: post.listing!,
          type: post.type,
          onOpen: onOpenListing,
          onMessage: onMessage,
        ),
      if (post.type == PostTypes.partnerAnnouncement)
        _PartnerCard(onContact: onMessage),
      if (post.original != null) _QuotedPost(original: post.original!),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}

BoxDecoration _box({Color? border}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border ?? AppColors.border),
    );

class _StampChip extends StatelessWidget {
  const _StampChip({required this.stamp});

  final PostStamp stamp;

  @override
  Widget build(BuildContext context) {
    final where = [
      stamp.eventName,
      if (stamp.city != null) stamp.city!,
    ].join(' · ');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: _box(border: AppColors.accent.withValues(alpha: 0.5)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 18,
              color: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${context.l10n.republicVerifiedStamp}: $where',
                style: AppTypography.body(size: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollView extends StatelessWidget {
  const _PollView({required this.poll, this.myUserId, this.onVote});

  final PostPoll poll;
  final String? myUserId;
  final ValueChanged<String>? onVote;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = poll.totalVotes;
    final mine = poll.pickedBy(myUserId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in poll.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _PollBar(
              label: o.label,
              share: total == 0 ? 0 : o.votes / total,
              picked: o.id == mine,
              onTap: onVote == null ? null : () => onVote!(o.id),
            ),
          ),
        Text(
          l10n.republicVotesCount(total),
          style: AppTypography.body(size: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PollBar extends StatelessWidget {
  const _PollBar({
    required this.label,
    required this.share,
    required this.picked,
    this.onTap,
  });

  final String label;
  final double share;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = picked ? AppColors.accent : AppColors.border;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: share.clamp(0, 1),
                child: ColoredBox(
                  color: AppColors.accent.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.body(
                        weight: FontWeight.w600,
                        color:
                            picked ? AppColors.accent : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${(share * 100).round()}%',
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final PostReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              const Spacer(),
              Text(
                l10n.republicVerifiedBooking,
                style: AppTypography.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(
              '“${review.comment}”',
              style: AppTypography.body(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({
    required this.item,
    required this.type,
    this.onOpen,
    this.onMessage,
  });

  final CatalogItem item;
  final String type;
  final VoidCallback? onOpen;
  final VoidCallback? onMessage;

  String _action(AppLocalizations l10n) => switch (type) {
        PostTypes.venueSpotlight => l10n.republicBookVenue,
        PostTypes.gearOffering => l10n.republicRentGear,
        PostTypes.serviceOffering => l10n.republicBookService,
        _ => l10n.republicGetTickets,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final price = catalogPriceLabel(
      l10n,
      item,
      locale: locale,
      formatter: ref.watch(moneyFormatterProvider),
    );
    final subtitle = [
      catalogSubtitle(l10n, item, locale: locale),
      if (price != null) price,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      decoration: _box(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.imageUrl != null)
            NetworkImageBox(url: item.imageUrl!, height: 140),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.body(weight: FontWeight.w700),
                ),
                if (item.category != null && item.category!.isNotEmpty)
                  Text(
                    categoryLabel(item.category!),
                    style: AppTypography.body(
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body(
                      size: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: onOpen,
                        child: Text(_action(l10n)),
                      ),
                    ),
                    if (onMessage != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l10n.republicMessage,
                        onPressed: onMessage,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({this.onContact});

  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(border: AppColors.accent.withValues(alpha: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.republicPartnerTitle,
                  style: AppTypography.body(
                    weight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.republicPartnerBody,
            style: AppTypography.body(size: 12, color: AppColors.textMuted),
          ),
          if (onContact != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: onContact,
              child: Text(l10n.republicContactPartner),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuotedPost extends StatelessWidget {
  const _QuotedPost({required this.original});

  final OriginalPost original;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: original.imageUrl != null
                  ? NetworkImageBox(url: original.imageUrl!, width: 48)
                  : ColoredBox(
                      color: AppColors.canvas,
                      child: Center(
                        child: Text(
                          original.authorName.isEmpty
                              ? '?'
                              : original.authorName.characters.first
                                  .toUpperCase(),
                          style: AppTypography.display(size: 18),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  original.authorName,
                  style: AppTypography.body(weight: FontWeight.w700),
                ),
                Text(
                  original.content.isEmpty
                      ? l10n.republicSharedPost
                      : original.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
