import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/asset_url.dart';
import 'package:flutter_template/shared/widgets/media_viewer.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:url_launcher/url_launcher.dart';

const _videoExtensions = ['.mp4', '.mov', '.webm', '.m4v'];

/// Whether [url] is a video, by its file ending.
bool isVideoUrl(String url) {
  final clean = url.split('?').first.toLowerCase();
  return _videoExtensions.any(clean.endsWith);
}

/// A post's photos and videos as one block, laid out like a feed: one wide,
/// two side by side, three with a big one, four or more in a grid with "+N" on
/// the last. A photo opens full screen; a video opens in the player app.
class PostMedia extends StatelessWidget {
  const PostMedia({required this.urls, super.key});

  final List<String> urls;

  static const _gap = 2.0;

  Future<void> _open(BuildContext context, int index) async {
    final url = urls[index];
    if (isVideoUrl(url)) {
      final uri = Uri.tryParse(resolveAssetUrl(url));
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    final photos = [
      for (final u in urls)
        if (!isVideoUrl(u)) u,
    ];
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MediaViewer(
          urls: photos,
          initialIndex: photos.indexOf(url),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, int i, {int more = 0}) {
    final url = urls[i];
    return GestureDetector(
      onTap: () => _open(context, i),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideoUrl(url))
            const ColoredBox(color: AppColors.surface)
          else
            NetworkImageBox(url: url),
          if (isVideoUrl(url))
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 52,
                color: AppColors.textPrimary,
              ),
            ),
          if (more > 0)
            ColoredBox(
              color: AppColors.scrim,
              child: Center(
                child: Text('+$more', style: AppTypography.display(size: 30)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = urls.length;
    if (n == 0) return const SizedBox.shrink();

    if (n == 1) {
      return SizedBox(
        height: 300,
        width: double.infinity,
        child: _tile(context, 0),
      );
    }
    if (n == 2) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(child: _tile(context, 0)),
            const SizedBox(width: _gap),
            Expanded(child: _tile(context, 1)),
          ],
        ),
      );
    }
    if (n == 3) {
      return SizedBox(
        height: 280,
        child: Row(
          children: [
            Expanded(flex: 3, child: _tile(context, 0)),
            const SizedBox(width: _gap),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(child: _tile(context, 1)),
                  const SizedBox(height: _gap),
                  Expanded(child: _tile(context, 2)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(context, 0)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _tile(context, 2)),
                const SizedBox(width: _gap),
                Expanded(child: _tile(context, 3, more: n - 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
