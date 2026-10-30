// Flutter web host: an `<iframe srcdoc>` inside an `HtmlElementView`.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// The browser can always host the globe page.
const bool globePlatformSupported = true;

final Set<String> _registered = <String>{};

/// The iframe behind each registered view type, so a pause can reach it.
final Map<String, web.HTMLIFrameElement> _frames =
    <String, web.HTMLIFrameElement>{};

bool _listening = false;
void Function(String city)? _onPin;
VoidCallback? _onReady;

/// One window listener for every globe; the latest build's callbacks win.
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
        if (message is! Map) return;
        if (message['fox'] == 'pin') {
          _onPin?.call('${message['city']}');
        } else if (message['fox'] == 'ready') {
          _onReady?.call();
        }
      } on FormatException {
        // Some other page's message.
      }
    }).toJS,
  );
}

/// Builds the iframe that draws [html]. [paused] freezes the page's motion and
/// resumes it without reloading, and [onReady] is called once the map has
/// drawn.
Widget buildGlobeView(
  String html, {
  bool interactive = false,
  bool paused = false,
  void Function(String city)? onPinTap,
  VoidCallback? onReady,
}) {
  _onPin = onPinTap;
  _onReady = onReady;
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
      _frames[viewType] = iframe;
      return iframe;
    });
  }

  return _GlobeFrame(viewType: viewType, paused: paused);
}

class _GlobeFrame extends StatefulWidget {
  const _GlobeFrame({required this.viewType, required this.paused});

  final String viewType;
  final bool paused;

  @override
  State<_GlobeFrame> createState() => _GlobeFrameState();
}

class _GlobeFrameState extends State<_GlobeFrame> {
  @override
  void didUpdateWidget(_GlobeFrame old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused) _run(on: !widget.paused);
  }

  /// Freezes or resumes the page's motion, without reloading it.
  void _run({required bool on}) {
    final message = jsonEncode({'fox': 'run', 'on': on});
    _frames[widget.viewType]?.contentWindow?.postMessage(
          message.toJS,
          '*'.toJS,
        );
  }

  @override
  Widget build(BuildContext context) =>
      HtmlElementView(viewType: widget.viewType);
}
