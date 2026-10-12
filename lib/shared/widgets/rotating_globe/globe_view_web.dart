// Flutter web host: an `<iframe srcdoc>` inside an `HtmlElementView`.
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The browser can always host the globe page.
const bool globePlatformSupported = true;

final Set<String> _registered = <String>{};

/// Builds the iframe that draws [html].
Widget buildGlobeView(String html) {
  // One registered view type per distinct page (token, colour, spin).
  final viewType = 'fox-globe-${html.hashCode}';

  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..srcdoc = html.toJS
        ..title = 'Rotating globe';
      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%'
        ..background = 'transparent'
        // Let Flutter receive the pointer events, so swiping the carousel or
        // scrolling the page works when a finger lands on the globe.
        ..pointerEvents = 'none';
      return iframe;
    });
  }

  return HtmlElementView(viewType: viewType);
}
