import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A row of vertical video tiles above the Republic's posts, the way a feed
/// shows Reels. A tile opens the full-screen videos page at that video;
/// "See all" opens it at the first. Shows nothing when the list has no video.
class VideosShelf extends StatelessWidget {
  const VideosShelf({
    required this.posts,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });

  /// The posts to pick videos from, in feed order.
  final List<Post> posts;
  final ValueChanged<Post> onOpen;
  final VoidCallback onSeeAll;

  static const _tileWidth = 104.0;
  static const double _tileHeight = _tileWidth * 16 / 9;
  static const _maxTiles = 10;

  @override
  Widget build(BuildContext context) {
    final videos = [
      for (final p in posts)
        if (p.videoUrl != null) p,
    ].take(_maxTiles).toList();
    if (videos.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline_rounded, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.republicVideos,
                    style: AppTypography.display(size: 18),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    minimumSize: const Size(48, 44),
                  ),
                  child: Text(l10n.republicVideosSeeAll),
                ),
              ],
            ),
          ),
          SizedBox(
            height: _tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _Tile(
                post: videos[i],
                onTap: () => onOpen(videos[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final poster = post.posterUrl;
    return Semantics(
      button: true,
      label: post.author.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: VideosShelf._tileWidth,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.surfaceRaised),
                if (poster != null)
                  Image.network(
                    resolveAssetUrl(poster),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1],
                      colors: [
                        AppColors.canvas.withValues(alpha: 0),
                        AppColors.canvas.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 36,
                    color: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    post.author.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
