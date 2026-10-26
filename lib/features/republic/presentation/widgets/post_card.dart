import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/domain/reaction.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_embeds.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_media.dart';
import 'package:flutter_template/features/republic/presentation/widgets/reaction_picker.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
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

/// One post, full width like a feed: who and when, the words, the first photo
/// edge to edge, the counts, then Like and Comment.
class PostCard extends StatefulWidget {
  const PostCard({
    required this.post,
    required this.onLike,
    required this.onComments,
    this.onMore,
    this.onReact,
    this.onReactions,
    this.myUserId,
    this.onVote,
    this.onOpenListing,
    this.onMessage,
    super.key,
  });

  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComments;

  /// Opens the post's ⋯ menu; no button when null.
  final VoidCallback? onMore;

  /// Chosen from the picker a long press on Like opens; no picker when null.
  final ValueChanged<ReactionType>? onReact;

  /// Opens who reacted how, from the counts row.
  final VoidCallback? onReactions;

  /// Who is looking, to mark their own poll vote.
  final String? myUserId;

  /// A poll option was tapped.
  final ValueChanged<String>? onVote;

  /// The listing a marketplace post points at was opened.
  final VoidCallback? onOpenListing;

  /// "Message" the author about this post or its listing.
  final VoidCallback? onMessage;

  /// Longer than this and the text folds behind "See more".
  static const foldAt = 280;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final onLike = widget.onLike;
    final onComments = widget.onComments;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final age = postAge(l10n, post.createdAt, locale);
    final muted = AppTypography.body(size: 13, color: AppColors.textMuted);

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isPinned)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.push_pin_outlined,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.republicPinned,
                    style: AppTypography.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                AuthorAvatar(author: post.author),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.name.isEmpty ? '—' : post.author.name,
                        style: AppTypography.body(weight: FontWeight.w700),
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
                if (widget.onMore != null)
                  IconButton(
                    tooltip: l10n.republicMore,
                    onPressed: widget.onMore,
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _Body(
                text: post.content,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
            ),
          PostEmbeds(
            post: post,
            myUserId: widget.myUserId,
            onVote: widget.onVote,
            onOpenListing: widget.onOpenListing,
            onMessage: widget.onMessage,
          ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            PostMedia(urls: post.mediaUrls),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                InkWell(
                  onTap: post.likesCount > 0 ? widget.onReactions : null,
                  child: Row(
                    children: [
                      if (post.myReaction != null &&
                          post.myReaction != ReactionType.like)
                        Text(
                          post.myReaction!.emoji,
                          style: const TextStyle(fontSize: 14),
                        )
                      else
                        const Icon(
                          Icons.favorite_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      const SizedBox(width: 4),
                      Text('${post.likesCount}', style: muted),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.republicCommentsCount(post.commentsCount),
                  style: muted,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: _LikeButton(
                  reaction: post.myReaction,
                  onTap: onLike,
                  onPick: widget.onReact,
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onComments,
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.textMuted,
                  ),
                  label: Text(
                    l10n.republicComments,
                    style: AppTypography.body(color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The words of a post, folded behind "See more" when they are long.
class _Body extends StatelessWidget {
  const _Body({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final long = text.length > PostCard.foldAt;
    final shown = long && !expanded
        ? text.substring(0, PostCard.foldAt).trimRight()
        : text;
    return Text.rich(
      TextSpan(
        style: AppTypography.body(),
        children: [
          ..._withMentions(shown),
          if (long) ...[
            TextSpan(text: expanded ? ' ' : '… '),
            TextSpan(
              text: expanded ? l10n.republicSeeLess : l10n.republicSeeMore,
              style: AppTypography.body(
                weight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
              recognizer: TapGestureRecognizer()..onTap = onToggle,
            ),
          ],
        ],
      ),
    );
  }
}

/// Like: a tap likes or takes the reaction back, a long press opens the six
/// reactions. Once reacted it shows that reaction's emoji and name.
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.reaction,
    required this.onTap,
    required this.onPick,
  });

  final ReactionType? reaction;
  final VoidCallback onTap;
  final ValueChanged<ReactionType>? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = reaction != null ? AppColors.accent : AppColors.textMuted;
    return Builder(
      builder: (anchor) => InkWell(
        onTap: onTap,
        onLongPress: onPick == null
            ? null
            : () async {
                final picked =
                    await showReactionPicker(anchor, current: reaction);
                if (picked != null) onPick!(picked);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (reaction != null)
                Text(reaction!.emoji, style: const TextStyle(fontSize: 18))
              else
                Icon(Icons.favorite_border_rounded, color: color),
              const SizedBox(width: 8),
              Text(
                reaction == null
                    ? l10n.republicLike
                    : reactionLabel(l10n, reaction!),
                style: AppTypography.body(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Words with each `@name` in the accent colour.
List<InlineSpan> _withMentions(String text) {
  final spans = <InlineSpan>[];
  var from = 0;
  for (final m in RegExp('@[A-Za-z0-9_]{1,32}').allMatches(text)) {
    if (m.start > 0 && !RegExp(r'\s').hasMatch(text[m.start - 1])) continue;
    if (m.start > from) {
      spans.add(TextSpan(text: text.substring(from, m.start)));
    }
    spans.add(
      TextSpan(
        text: m.group(0),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    from = m.end;
  }
  if (from < text.length) spans.add(TextSpan(text: text.substring(from)));
  return spans;
}
