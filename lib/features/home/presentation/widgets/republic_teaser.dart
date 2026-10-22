import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/presentation/widgets/section_title.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The two latest community posts, so Home shows the app is alive. Opens the
/// Republic. Nothing while the feed loads, when it is empty, or if it fails.
class RepublicTeaser extends ConsumerWidget {
  const RepublicTeaser({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref
            .watch(feedControllerProvider(null))
            .asData
            ?.value
            .posts
            .where((p) => p.content.isNotEmpty)
            .take(2)
            .toList() ??
        const <Post>[];
    if (posts.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: l10n.homeRepublicTitle,
            action: l10n.seeAll,
            onAction: onOpen,
          ),
          const SizedBox(height: 4),
          for (final post in posts) ...[
            _PostCard(post: post, onTap: onOpen),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = post.author.name;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Semantics(
      button: true,
      label: '$name: ${post.content}',
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: post.author.imageUrl == null
                      ? Container(
                          width: 36,
                          height: 36,
                          color: AppColors.surfaceRaised,
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: AppTypography.display(size: 15),
                          ),
                        )
                      : PhotoBox(
                          url: post.author.imageUrl,
                          width: 36,
                          height: 36,
                          radius: 18,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(size: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(size: 13),
                      ),
                    ],
                  ),
                ),
                if (post.likesCount > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${post.likesCount}',
                    style: AppTypography.body(size: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
