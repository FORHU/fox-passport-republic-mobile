import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// "5m", "3h", "2d", or the date once it is older than a week.
String postAge(
  AppLocalizations l10n,
  DateTime? at,
  String locale, {
  DateTime? now,
}) {
  if (at == null) return '';
  final diff = (now ?? DateTime.now()).difference(at);
  if (diff.inMinutes < 1) return l10n.republicJustNow;
  if (diff.inMinutes < 60) return l10n.republicMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.republicHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.republicDaysAgo(diff.inDays);
  return DateFormat.MMMd(locale).format(at);
}

/// A person's avatar: their photo, or their initial.
class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({required this.author, this.size = 40, super.key});

  final PostAuthor author;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = author.name.isEmpty ? '?' : author.name;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: author.imageUrl == null
            ? ColoredBox(
                color: AppColors.surface,
                child: Center(
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: AppTypography.display(size: size * 0.4),
                  ),
                ),
              )
            : NetworkImageBox(
                url: author.imageUrl!,
                width: size,
                height: size,
              ),
      ),
    );
  }
}

/// One post: who and when, the words, the first photo, then like and comment.
class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.onLike,
    required this.onComments,
    super.key,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final age = postAge(l10n, post.createdAt, locale);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AuthorAvatar(author: post.author),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author.name.isEmpty ? '—' : post.author.name,
                      style: AppTypography.body(weight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (age.isNotEmpty) age,
                        if (post.edited) l10n.republicEdited,
                      ].join(' · '),
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
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.content, style: AppTypography.body()),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            NetworkImageBox(
              url: post.mediaUrls.first,
              height: 200,
              width: double.infinity,
              borderRadius: AppRadius.brMd,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(
                  post.isLikedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      post.isLikedByMe ? AppColors.accent : AppColors.textMuted,
                ),
                label: Text(
                  '${post.likesCount}',
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ),
              TextButton.icon(
                onPressed: onComments,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.textMuted,
                ),
                label: Text(
                  '${post.commentsCount}',
                  style: AppTypography.body(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
