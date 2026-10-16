import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart'
    show ImageRenderMethodForWeb;
import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/shared/widgets/brand_logo.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Cached remote image. While it loads it shows a softly pulsing tile with the
/// FoxPassport mark; if it cannot load, the same tile with a retry icon that
/// tries again when tapped.
class NetworkImageBox extends StatefulWidget {
  const NetworkImageBox({
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  State<NetworkImageBox> createState() => _NetworkImageBoxState();
}

class _NetworkImageBoxState extends State<NetworkImageBox> {
  /// Bumped on retry so the image widget starts over.
  int _attempt = 0;

  Future<void> _retry(String resolved) async {
    await CachedNetworkImage.evictFromCache(resolved);
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAssetUrl(widget.url);
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        key: ValueKey('$resolved#$_attempt'),
        imageUrl: resolved,
        // On Flutter web the default (an <img> element) stops decoding after
        // a tab switch and every image then fails. Fetching the bytes avoids
        // it.
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (context, url) => _Tile(
          width: widget.width,
          height: widget.height,
          pulse: true,
        ),
        errorWidget: (context, url, error) => _Tile(
          width: widget.width,
          height: widget.height,
          onRetry: () => _retry(resolved),
        ),
      ),
    );
  }
}

/// The branded stand-in: the mark on a dark tile. [pulse] breathes while
/// loading; [onRetry] turns it into a "tap to retry" tile.
class _Tile extends StatefulWidget {
  const _Tile({this.width, this.height, this.pulse = false, this.onRetry});

  final double? width;
  final double? height;
  final bool pulse;
  final VoidCallback? onRetry;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = [
      if (widget.width != null && widget.width!.isFinite) widget.width!,
      if (widget.height != null && widget.height!.isFinite) widget.height!,
    ];
    final side = shortest.isEmpty
        ? 32.0
        : (shortest.reduce((a, b) => a < b ? a : b) * 0.35).clamp(18.0, 44.0);

    final retry = widget.onRetry;
    final tile = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        color: Color.lerp(
          AppColors.surface,
          AppColors.surfaceRaised,
          widget.pulse ? _controller.value : 0.5,
        ),
        alignment: Alignment.center,
        child: child,
      ),
      child: retry == null
          ? Opacity(opacity: 0.35, child: FoxLogo(size: side))
          : Icon(
              Icons.refresh_rounded,
              size: side,
              color: AppColors.textMuted,
              semanticLabel: 'Retry',
            ),
    );

    if (retry == null) return tile;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: retry,
      child: tile,
    );
  }
}
