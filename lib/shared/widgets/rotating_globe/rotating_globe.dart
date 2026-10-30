import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/globe_view_io.dart'
    if (dart.library.js_interop) 'package:flutter_template/shared/widgets/rotating_globe/globe_view_web.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

export 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart'
    show GlobeLook, GlobeStop;

/// The web landing's hero globe, for the phone: a Mapbox globe with NASA city
/// lights, a dusk sky with stars, event pins and callout cards, turning at
/// 5°/s.
///
/// Renders Mapbox GL JS in an iframe on Flutter web and a WebView on
/// Android / iOS. Shows a static placeholder when `MAPBOX_ACCESS_TOKEN` is
/// empty or the platform can't host a web view, so a missing token never
/// breaks the screen.
///
/// The globe takes no input: touches pass through to whatever is behind it, so
/// it can sit under a carousel or inside a scroll view.
///
/// Give it a fixed [size] for a square globe, or leave [size] null to fill
/// the space it is placed in (the hero / backdrop use).
class RotatingGlobe extends StatelessWidget {
  const RotatingGlobe({
    this.size,
    this.background = AppColors.canvas,
    this.stops = const [],
    this.bottomInset = 0,
    this.nightLights = true,
    this.maxCards = 2,
    this.interactive = false,
    this.startLat = 14,
    this.startLng = 121,
    this.zoom,
    this.look = GlobeLook.standard,
    this.spin = true,
    this.degreesPerSecond = 5,
    this.paused = false,
    this.still,
    this.onStopTap,
    super.key,
  });

  /// Width and height in logical pixels, or null to fill the parent.
  final double? size;

  /// The colour of the surface the globe sits on (`canvas` or `surface`), so
  /// its canvas disappears into it.
  final Color background;

  /// Event locations to pin, busiest first.
  final List<GlobeStop> stops;

  /// Space reserved at the bottom (for text laid over the globe); the globe is
  /// centred in what is left above.
  final double bottomInset;

  final bool nightLights;

  /// How many of [stops] also get a callout card.
  final int maxCards;

  /// Lets a finger turn and pinch the globe. Off, touches pass through.
  final bool interactive;

  /// Where the globe is centred, and an optional fixed zoom.
  final double startLat;
  final double startLng;
  final double? zoom;

  /// How the globe is painted: the web hero's dusk look, or the neon one.
  final GlobeLook look;

  /// Whether the globe turns. Off, it stays on [startLat] / [startLng]. Reduced
  /// motion turns it off whatever this says.
  final bool spin;

  /// How fast the globe turns, in degrees of longitude a second. 5 is the web
  /// hero's speed.
  final double degreesPerSecond;

  /// Freezes the globe's motion (turning and pulsing pins) and resumes it,
  /// without reloading the map.
  final bool paused;

  /// A picture shown over the live globe until it has drawn, then faded out.
  /// It is also what shows when there is no Mapbox token or
  /// the platform can't host a web view, so a slow or missing map never leaves
  /// a blank space. Null shows a flat placeholder in those cases.
  final Widget? still;

  /// Called with the city of a pin the person tapped (interactive only).
  final ValueChanged<String>? onStopTap;

  /// `#RRGGBB` for the page's CSS.
  static String _hex(Color c) {
    final rgb = c.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final token = AppConfig.instance.mapboxToken;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget live(VoidCallback? onReady) => buildGlobeView(
          buildGlobeHtml(
            token: token,
            background: _hex(background),
            spin: spin && !reduceMotion,
            animate: !reduceMotion,
            degreesPerSecond: degreesPerSecond,
            bottomInset: bottomInset,
            nightLights: nightLights,
            stops: stops,
            maxCards: maxCards,
            interactive: interactive,
            startLat: startLat,
            startLng: startLng,
            zoom: zoom,
            look: look,
          ),
          interactive: interactive,
          paused: paused,
          onPinTap: onStopTap,
          onReady: onReady,
        );

    final Widget child;
    if (token.isEmpty || !globePlatformSupported) {
      child = still ??
          _GlobePlaceholder(background: background, bottomInset: bottomInset);
    } else if (still != null) {
      child = _Reveal(still: still!, live: live);
    } else {
      child = live(null);
    }

    final framed = ColoredBox(color: background, child: child);

    return Semantics(
      label: 'Rotating globe',
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: IgnorePointer(
            ignoring: !interactive,
            child: size == null
                ? framed
                : SizedBox.square(dimension: size, child: framed),
          ),
        ),
      ),
    );
  }
}

/// Shows [still] over the live globe until the live globe says it has drawn,
/// then fades [still] out.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.still, required this.live});

  final Widget still;
  final Widget Function(VoidCallback onReady) live;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  static const _fade = Duration(milliseconds: 600);

  bool _ready = false;

  /// The still is dropped once it has faded out over the live globe, so it is
  /// not painted for nothing.
  bool _stillGone = false;
  Timer? _drop;

  void _markReady() {
    if (!mounted || _ready) return;
    setState(() => _ready = true);
    _drop = Timer(_fade, () {
      if (mounted) setState(() => _stillGone = true);
    });
  }

  @override
  void dispose() {
    _drop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The live globe is underneath and fully opaque from the start: a platform
    // view that is not painted (opacity 0) is never created, so it would never
    // load and never say it is ready. The still picture sits on top of it and
    // fades out once it has. The live globe is the first child, so dropping the
    // still later does not rebuild it.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.live(_markReady),
        if (!_stillGone)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _ready ? 0 : 1,
              duration: _fade,
              child: widget.still,
            ),
          ),
      ],
    );
  }
}

/// A flat disc standing in for the globe.
class _GlobePlaceholder extends StatelessWidget {
  const _GlobePlaceholder({
    required this.background,
    required this.bottomInset,
  });

  final Color background;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.hasBoundedHeight
            ? constraints.maxHeight - bottomInset
            : constraints.maxWidth;
        final disc = (usable.isFinite ? usable : constraints.maxWidth) * 0.72;
        final side = disc.clamp(40.0, constraints.maxWidth * 0.9);

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceRaised,
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: Icon(
                Icons.public_rounded,
                size: side * 0.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        );
      },
    );
  }
}
