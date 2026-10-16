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

/// Builds the web view that draws [html].
Widget buildGlobeView(
  String html, {
  bool interactive = false,
  void Function(String city)? onPinTap,
}) =>
    _MobileGlobe(html: html, onPinTap: onPinTap);

class _MobileGlobe extends StatefulWidget {
  const _MobileGlobe({required this.html, this.onPinTap});

  final String html;
  final void Function(String city)? onPinTap;

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
    unawaited(_controller.loadHtmlString(widget.html));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
