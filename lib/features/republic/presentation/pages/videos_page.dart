import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/reel_player.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_actions.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

/// The Republic's videos, one to a screen, swiped up and down like Reels or
/// TikTok. The server shrinks every upload to 9:16, 720x1280, so a clip fills
/// the phone. The one on screen plays (muted at first, looping); the next and
/// the last are got ready so a swipe does not wait.
class VideosPage extends ConsumerStatefulWidget {
  const VideosPage({super.key});

  @override
  ConsumerState<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends ConsumerState<VideosPage>
    with WidgetsBindingObserver {
  final _pages = PageController();

  /// The players that are ready or getting ready, by post id: the video on
  /// screen and the ones either side of it.
  final _players = <String, VideoPlayerController>{};
  final _failed = <String>{};

  int _index = 0;
  bool _muted = true;
  bool _userPaused = false;
  bool _appActive = true;

  /// How many times the page asked for more because it had no video to show.
  int _emptyLoads = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    for (final p in _players.values) {
      unawaited(p.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _applyPlayback();
  }

  /// Gets the players for the video on screen and its neighbours going, and
  /// lets go of the rest.
  void _sync(List<Post> videos) {
    final wanted = <String>{
      for (var i = _index - 1; i <= _index + 1; i++)
        if (i >= 0 && i < videos.length) videos[i].id,
    };
    var changed = false;
    for (final id in _players.keys.toList()) {
      if (!wanted.contains(id)) {
        unawaited(_players.remove(id)!.dispose());
        changed = true;
      }
    }
    for (final id in wanted) {
      if (_players.containsKey(id) || _failed.contains(id)) continue;
      final post = videos.firstWhere((p) => p.id == id);
      final url = post.videoUrl;
      if (url == null) continue;
      final player = ref.read(reelPlayerFactoryProvider)(resolveAssetUrl(url));
      _players[id] = player;
      changed = true;
      unawaited(_start(id, player));
    }
    _applyPlayback(videos);
    // The pages hold their player, so they are built again with the new ones.
    if (changed) setState(() {});
  }

  Future<void> _start(String id, VideoPlayerController player) async {
    try {
      await player.initialize();
      if (!mounted || _players[id] != player) return;
      await player.setLooping(true);
      await player.setVolume(_muted ? 0 : 1);
      _applyPlayback();
    } on Object {
      if (!mounted || _players[id] != player) return;
      setState(() {
        _failed.add(id);
        _players.remove(id);
      });
      unawaited(player.dispose());
    }
  }

  List<Post> _videos = const [];

  /// Plays the video on screen, unless it was paused or the app is in the
  /// background, and holds the others.
  void _applyPlayback([List<Post>? videos]) {
    final list = videos ?? _videos;
    final current =
        _index >= 0 && _index < list.length ? list[_index].id : null;
    for (final entry in _players.entries) {
      final player = entry.value;
      if (!player.value.isInitialized) continue;
      final play = entry.key == current && !_userPaused && _appActive;
      if (play && !player.value.isPlaying) {
        unawaited(player.play());
      } else if (!play && player.value.isPlaying) {
        unawaited(player.pause());
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _userPaused = false;
    });
    _sync(_videos);
    final feed = ref.read(feedControllerProvider(null)).value;
    if (feed != null &&
        feed.hasMore &&
        !feed.loadingMore &&
        index >= _videos.length - 3) {
      unawaited(ref.read(feedControllerProvider(null).notifier).loadMore());
    }
  }

  void _togglePause() {
    setState(() => _userPaused = !_userPaused);
    _applyPlayback();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    for (final p in _players.values) {
      if (p.value.isInitialized) unawaited(p.setVolume(_muted ? 0 : 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(feedControllerProvider(null));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: feed.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => _Plain(
          child: AppStateView(
            kind: AppStateKind.error,
            title: l10n.apiLoadFailed,
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(feedControllerProvider(null)),
          ),
        ),
        data: (state) {
          final videos = [
            for (final p in state.posts)
              if (p.videoUrl != null) p,
          ];
          _videos = videos;
          if (_index >= videos.length && videos.isNotEmpty) {
            _index = videos.length - 1;
          }

          // The feed's pages hold few videos: ask for more until there is one
          // to show, or the feed is out.
          if (videos.isEmpty &&
              state.hasMore &&
              !state.loadingMore &&
              _emptyLoads < 8) {
            _emptyLoads++;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              unawaited(
                ref.read(feedControllerProvider(null).notifier).loadMore(),
              );
            });
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _sync(videos);
          });

          if (videos.isEmpty) {
            final loading = state.hasMore && _emptyLoads < 8;
            return _Plain(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    )
                  : AppStateView(
                      kind: AppStateKind.empty,
                      icon: Icons.play_circle_outline_rounded,
                      title: l10n.republicVideosEmpty,
                      message: l10n.republicVideosEmptyHint,
                    ),
            );
          }

          return PageView.builder(
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, i) {
              final post = videos[i];
              return _ReelPage(
                key: ValueKey(post.id),
                post: post,
                player: _players[post.id],
                failed: _failed.contains(post.id),
                active: i == _index,
                muted: _muted,
                paused: _userPaused && i == _index,
                onTap: _togglePause,
                onMute: _toggleMute,
                actions: PostActions(context, ref, null),
              );
            },
          );
        },
      ),
    );
  }
}

/// A plain page with a back arrow, for a loading, empty or failed state.
class _Plain extends StatelessWidget {
  const _Plain({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              left: 4,
              top: 4,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ],
        ),
      );
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.post,
    required this.player,
    required this.failed,
    required this.active,
    required this.muted,
    required this.paused,
    required this.onTap,
    required this.onMute,
    required this.actions,
    super.key,
  });

  final Post post;
  final VideoPlayerController? player;
  final bool failed;
  final bool active;
  final bool muted;
  final bool paused;
  final VoidCallback onTap;
  final VoidCallback onMute;
  final PostActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = player;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.canvas),
        // The poster holds the screen until the first frame is ready.
        if (post.posterUrl != null)
          Image.network(
            resolveAssetUrl(post.posterUrl!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        if (controller != null)
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (!value.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }
              return FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: VideoPlayer(controller),
                ),
              );
            },
          )
        else if (!failed)
          const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        // A tap anywhere on the picture plays or pauses.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
          ),
        ),
        const _Shade(),
        if (paused)
          const Center(
            child: IgnorePointer(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 84,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        if (failed)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.republicVideoFailed,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                children: [
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: muted
                        ? l10n.republicVideoSoundOn
                        : l10n.republicVideoSoundOff,
                    onPressed: onMute,
                    icon: Icon(
                      muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _Caption(post: post)),
                  const SizedBox(width: 12),
                  _Rail(post: post, actions: actions),
                ],
              ),
            ),
          ),
        ),
        // How far along it is, as a thin line at the bottom.
        if (controller != null && active)
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 3,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: false,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.textPrimary,
                  bufferedColor: AppColors.border,
                  backgroundColor: AppColors.surfaceRaised,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A fade at the bottom so the words read over any picture.
class _Shade extends StatelessWidget {
  const _Shade();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.55, 1],
              colors: [
                AppColors.canvas.withValues(alpha: 0.35),
                AppColors.canvas.withValues(alpha: 0),
                AppColors.canvas.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      );
}

class _Caption extends StatelessWidget {
  const _Caption({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final name = post.author.name;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarImage(
              url: post.author.imageUrl,
              radius: 16,
              fallback: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: AppTypography.display(
                  size: 13,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(),
              ),
            ),
          ],
        ),
        if (post.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            post.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(color: AppColors.textPrimary),
          ),
        ],
      ],
    );
  }
}

/// Like, comments, share and the post's menu, down the right edge.
class _Rail extends StatelessWidget {
  const _Rail({required this.post, required this.actions});

  final Post post;
  final PostActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailButton(
          tooltip: l10n.republicLike,
          icon: post.isLikedByMe
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: post.isLikedByMe ? AppColors.accent : AppColors.textPrimary,
          label: '${post.likesCount}',
          onTap: () => unawaited(actions.like(post.id)),
        ),
        _RailButton(
          tooltip: l10n.republicComments,
          icon: Icons.chat_bubble_outline_rounded,
          label: '${post.commentsCount}',
          onTap: () => unawaited(actions.comments(post.id)),
        ),
        _RailButton(
          tooltip: l10n.republicShare,
          icon: Icons.share_outlined,
          label: l10n.republicShare,
          onTap: () => unawaited(actions.share(post)),
        ),
        _RailButton(
          tooltip: l10n.republicMore,
          icon: Icons.more_horiz_rounded,
          onTap: () => unawaited(actions.menu(post)),
        ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.label,
    this.color = AppColors.textPrimary,
  });

  final String tooltip;
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: tooltip,
              onPressed: onTap,
              iconSize: 32,
              icon: Icon(icon, color: color),
            ),
            if (label != null)
              Text(
                label!,
                style:
                    AppTypography.body(size: 12, color: AppColors.textPrimary),
              ),
          ],
        ),
      );
}
