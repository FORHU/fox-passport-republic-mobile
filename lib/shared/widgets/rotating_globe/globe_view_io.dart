// Android / iOS host: a transparent `WebView` loading the globe page.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
