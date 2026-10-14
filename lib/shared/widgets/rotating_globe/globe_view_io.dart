// Android / iOS host: a transparent `WebView` loading the globe page.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// `webview_flutter` has no desktop implementation, so on Windows, macOS and
/// Linux the globe falls back to its placeholder.
bool get globePlatformSupported =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Builds the web view that draws [html].
Widget buildGlobeView(String html) => _MobileGlobe(html: html);

class _MobileGlobe extends StatefulWidget {
  const _MobileGlobe({required this.html});

  final String html;

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
    unawaited(_controller.setBackgroundColor(AppColors.clear));
    unawaited(_controller.loadHtmlString(widget.html));
  }

  @override
  void didUpdateWidget(_MobileGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The page was only loaded in initState, so a new html string (a hot
    // reload of the globe code, or a changed colour / spin / stops) was
    // ignored until the app was restarted.
    if (oldWidget.html != widget.html) {
      unawaited(_controller.loadHtmlString(widget.html));
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
