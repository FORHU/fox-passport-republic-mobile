// Flutter web host: an `<iframe srcdoc>` inside an `HtmlElementView`.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The browser can always host the globe page.
const bool globePlatformSupported = true;

final Set<String> _registered = <String>{};

bool _listening = false;
void Function(String city)? _onPin;

/// One window listener for every globe; the latest build's callback wins.
void _listen() {
  if (_listening) return;
  _listening = true;
  web.window.addEventListener(
    'message',
    ((web.MessageEvent event) {
      final raw = event.data.dartify();
      if (raw is! String) return;
      try {
        final message = jsonDecode(raw);
        if (message is Map && message['fox'] == 'pin') {
          _onPin?.call('${message['city']}');
        }
      } on FormatException {
        // Some other page's message.
      }
    }).toJS,
  );
}

/// Builds the iframe that draws [html].
Widget buildGlobeView(
  String html, {
  bool interactive = false,
  void Function(String city)? onPinTap,
}) {
  _onPin = onPinTap;
  _listen();
  // One registered view type per distinct page (token, colour, spin).
  final viewType = 'fox-globe-${interactive ? 'i' : 'p'}-${html.hashCode}';

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
        ..pointerEvents = interactive ? 'auto' : 'none';
      return iframe;
    });
  }

  return HtmlElementView(viewType: viewType);
}
