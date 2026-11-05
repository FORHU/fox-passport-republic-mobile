import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/republic/data/feed_video_focus.dart';
import 'package:flutter_template/features/republic/data/reel_player.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:video_player/video_player.dart';

/// A video in a post, in the feed. Its poster shows at first; once most of it
/// is on screen and it is the one chosen by [FeedVideoFocus], it plays muted
/// and looping, and lets go of its player when it scrolls away. A tap opens it
/// in the full-screen Videos view; the corner button turns the sound on.
class FeedVideo extends ConsumerStatefulWidget {
  const FeedVideo({
    required this.post,
    required this.url,
    required this.onOpen,
    super.key,
  });

  final Post post;
  final String url;
  final VoidCallback onOpen;

  @override
  ConsumerState<FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends ConsumerState<FeedVideo> {
  late final FeedVideoFocus _focus = ref.read(feedVideoFocusProvider);
  ScrollPosition? _position;
  VideoPlayerController? _player;
  bool _failed = false;
  bool _active = true;

  String get _id => '${widget.post.id}|${widget.url}';

  @override
  void initState() {
    super.initState();
    _focus
      ..addListener(_onFocus)
      ..muted.addListener(_onMuted);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position?..addListener(_check);
    }
    // Not on screen to the user while another bottom tab, or a page over this
    // one, is showing.
    _active = TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(FeedVideo old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _focus
      ..removeListener(_onFocus)
      ..muted.removeListener(_onMuted);
    final player = _player;
    _player = null;
    if (player != null) unawaited(player.dispose());
    // Told after the tree is done changing: the others rebuild on it.
    final focus = _focus;
    final id = _id;
    scheduleMicrotask(() => focus.release(id));
    super.dispose();
  }

  /// Tells the focus how much of this video shows.
  void _check() {
    if (!mounted) return;
    _focus.report(_id, _active ? _visibleFraction() : 0);
  }

  double _visibleFraction() {
    final box = context.findRenderObject();
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return 0;
    if (viewport is! RenderBox || !viewport.attached) return 0;
    final height = box.size.height;
    if (height <= 0) return 0;
    final top = box.localToGlobal(Offset.zero).dy;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewport.size.height;
    final visible =
        math.min(top + height, viewportBottom) - math.max(top, viewportTop);
    return (visible / height).clamp(0.0, 1.0);
  }

  void _onFocus() {
    if (!mounted) return;
    final mine = _focus.value == _id;
    if (mine && _player == null && !_failed) {
      unawaited(_start());
    } else if (!mine && _player != null) {
      final player = _player!;
      setState(() => _player = null);
      unawaited(player.dispose());
    }
  }

  void _onMuted() {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    unawaited(player.setVolume(_focus.muted.value ? 0 : 1));
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    final player = ref.read(reelPlayerFactoryProvider)(
      resolveAssetUrl(widget.url),
    );
    setState(() => _player = player);
    try {
      await player.initialize();
      if (!mounted || _player != player) return;
      await player.setLooping(true);
      await player.setVolume(_focus.muted.value ? 0 : 1);
      await player.play();
      if (mounted && _player == player) setState(() {});
    } on Object {
      if (!mounted || _player != player) return;
      setState(() {
        _failed = true;
        _player = null;
      });
      unawaited(player.dispose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = _player;
    final poster = widget.post.posterUrl;
    final muted = _focus.muted.value;

    return GestureDetector(
      onTap: widget.onOpen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.surface),
          if (poster != null)
            Image.network(
              resolveAssetUrl(poster),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          if (player != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: player,
              builder: (context, value, _) {
                if (!value.isInitialized) return const SizedBox.shrink();
                return FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: value.size.width,
                    height: value.size.height,
                    child: VideoPlayer(player),
                  ),
                );
              },
            ),
          // The play mark until it is playing.
          if (player == null || !player.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 52,
                color: AppColors.textPrimary,
              ),
            ),
          if (player != null && player.value.isInitialized)
            Positioned(
              right: 4,
              bottom: 4,
              child: IconButton(
                tooltip: muted
                    ? l10n.republicVideoSoundOn
                    : l10n.republicVideoSoundOff,
                onPressed: () => _focus.muted.value = !muted,
                icon: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
