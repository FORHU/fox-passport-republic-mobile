import 'package:flutter/material.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/globe_view_io.dart'
    if (dart.library.js_interop) 'package:flutter_template/shared/widgets/rotating_globe/globe_view_web.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

export 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart'
    show GlobeStop;

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

  /// `#RRGGBB` for the page's CSS.
  static String _hex(Color c) {
    final rgb = c.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final token = AppConfig.instance.mapboxToken;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget child = (token.isEmpty || !globePlatformSupported)
        ? _GlobePlaceholder(background: background, bottomInset: bottomInset)
        : buildGlobeView(
            buildGlobeHtml(
              token: token,
              background: _hex(background),
              spin: !reduceMotion,
              bottomInset: bottomInset,
              nightLights: nightLights,
              stops: stops,
              maxCards: maxCards,
            ),
          );

    final framed = ColoredBox(color: background, child: child);

    return Semantics(
      label: 'Rotating globe',
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: IgnorePointer(
            child: size == null
                ? framed
                : SizedBox.square(dimension: size, child: framed),
          ),
        ),
      ),
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
