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
<<<<<<< HEAD
    unawaited(
      _controller.addJavaScriptChannel(
        'FoxPin',
        onMessageReceived: (message) => widget.onPinTap?.call(message.message),
      ),
    );
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
=======
    unawaited(_controller.setBackgroundColor(const Color(0x00000000)));
    unawaited(_controller.loadHtmlString(widget.html));
>>>>>>> 8685e43a59ba05d13b4e6e8d7f8aae2d44061c70
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
