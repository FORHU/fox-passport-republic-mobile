// Android / iOS host: a transparent `WebView` loading the globe page.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// `webview_flutter` has no desktop implementation, so on Windows, macOS and
/// Linux the globe falls back to its placeholder.
bool get globePlatformSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Builds the web view that draws [html]. [paused] freezes the page's motion
/// and resumes it without reloading, and [onReady] is called once the map has
/// drawn.
Widget buildGlobeView(
  String html, {
  bool interactive = false,
  bool paused = false,
  void Function(String city)? onPinTap,
  VoidCallback? onReady,
}) =>
    _MobileGlobe(html: html, paused: paused, onReady: onReady);

class _MobileGlobe extends StatefulWidget {
  const _MobileGlobe({
    required this.html,
    required this.paused,
    this.onReady,
  });

  final String html;
  final bool paused;
  final VoidCallback? onReady;

  @override
  State<_MobileGlobe> createState() => _MobileGlobeState();
}

class _MobileGlobeState extends State<_MobileGlobe> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(_controller.setBackgroundColor(Colors.transparent));
    unawaited(
      _controller.addJavaScriptChannel(
        'FoxGlobe',
        onMessageReceived: (message) {
          if (message.message == 'ready') widget.onReady?.call();
        },
      ),
    );
    unawaited(_controller.loadHtmlString(widget.html));
    if (widget.paused) unawaited(_run(on: false));
  }

  @override
  void didUpdateWidget(_MobileGlobe old) {
    super.didUpdateWidget(old);
    // Freeze or resume the page's motion; the page itself is not reloaded.
    if (old.paused != widget.paused) unawaited(_run(on: !widget.paused));
  }

  Future<void> _run({required bool on}) => _controller
      .runJavaScript('window.foxSetRunning && window.foxSetRunning($on)');

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
