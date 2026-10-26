import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Photos full screen: swipe between them, pinch to zoom, back to close.
class MediaViewer extends StatefulWidget {
  const MediaViewer({required this.urls, this.initialIndex = 0, super.key});

  final List<String> urls;
  final int initialIndex;

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _controller;
  late int _index = widget.initialIndex.clamp(0, widget.urls.length - 1);

  /// Swiping is off while a photo is zoomed in, so a drag pans it instead.
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: widget.urls.length > 1
            ? Text('${_index + 1} / ${widget.urls.length}')
            : null,
      ),
      body: PageView.builder(
        controller: _controller,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => _Zoomable(
          url: widget.urls[i],
          onZoom: (z) {
            if (z != _zoomed) setState(() => _zoomed = z);
          },
        ),
      ),
    );
  }
}

class _Zoomable extends StatefulWidget {
  const _Zoomable({required this.url, required this.onZoom});

  final String url;
  final ValueChanged<bool> onZoom;

  @override
  State<_Zoomable> createState() => _ZoomableState();
}

class _ZoomableState extends State<_Zoomable> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: 4,
      onInteractionEnd: (_) =>
          widget.onZoom(_transform.value.getMaxScaleOnAxis() > 1.01),
      child: Center(
        child: NetworkImageBox(url: widget.url, fit: BoxFit.contain),
      ),
    );
  }
}
