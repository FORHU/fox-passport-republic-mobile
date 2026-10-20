import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Where a venue or event is: a heading, the place, and a map with a lime pin,
/// as the web draws it. The exact spot is only given after booking, so there
/// is no way to open directions from here.
///
/// The map is Mapbox's dark style, as on the web, and needs the app's public
/// Mapbox token. With no coordinates, or no token, the map is a placeholder
/// panel. Draws nothing when there is no place and no coordinates either.
class LocationCard extends StatelessWidget {
  const LocationCard({
    required this.title,
    required this.place,
    this.lat,
    this.lng,
    this.mapboxToken,
    this.tileProvider,
    super.key,
  });

  final String title;

  /// "Baguio, Benguet": the town the place is in.
  final String place;
  final double? lat;
  final double? lng;

  /// The Mapbox public token; the app's configured one unless a test sets it.
  @visibleForTesting
  final String? mapboxToken;

  /// Where the map tiles come from; the network unless a test swaps it.
  @visibleForTesting
  final TileProvider? tileProvider;

  /// Mapbox's dark style (`dark-v11`), the same one the web uses, as 256 px
  /// tiles; `{r}` becomes `@2x` on a sharp screen.
  static String _tileUrl(String token) =>
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/'
      '{z}/{x}/{y}{r}?access_token=$token';

  static String _configuredToken() {
    try {
      return AppConfig.instance.mapboxToken;
    } on Object {
      // Config not loaded (some tests): no map.
      return '';
    }
  }

  bool get _hasPin => lat != null && lng != null;

  @override
  Widget build(BuildContext context) {
    final hasPlace = place.trim().isNotEmpty;
    if (!hasPlace && !_hasPin) return const SizedBox.shrink();
    final l10n = context.l10n;
    final token = (mapboxToken ?? _configuredToken()).trim();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.display(size: 18)),
          if (hasPlace) ...[
            const SizedBox(height: 4),
            Text(place.trim(), style: AppTypography.body(size: 13)),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.brCard,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brCard,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  if (_hasPin && token.isNotEmpty)
                    _PinMap(
                      point: LatLng(lat!, lng!),
                      tileUrl: _tileUrl(token),
                      tileProvider: tileProvider,
                    )
                  else
                    const _NoPin(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _Chip(text: l10n.locationAfterBooking),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinMap extends StatelessWidget {
  const _PinMap({
    required this.point,
    required this.tileUrl,
    this.tileProvider,
  });

  final LatLng point;
  final String tileUrl;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 12,
        minZoom: 3,
        maxZoom: 18,
        backgroundColor: AppColors.surface,
        // Two fingers move and zoom the map; one finger still scrolls the
        // page, so the map never traps it.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom |
              InteractiveFlag.pinchMove |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.example.flutter_template',
          retinaMode: RetinaMode.isHighDensity(context),
          tileProvider: tileProvider,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 28,
              height: 36,
              // The tip of the pin sits on the point.
              alignment: Alignment.topCenter,
              child: const CustomPaint(painter: _PinPainter()),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 6, 2),
            child: Text(
              '© Mapbox © OpenStreetMap',
              style: TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown when the venue or event has no pin yet.
class _NoPin extends StatelessWidget {
  const _NoPin();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(
          Icons.location_off_outlined,
          size: 34,
          color: AppColors.textFaint,
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: AppRadius.brPill,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvas.withValues(alpha: 0.8),
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Text(
              text,
              style: AppTypography.label(color: AppColors.textPrimary),
            ),
          ),
        ),
      );
}

/// The web's map pin: a lime teardrop with a dark centre.
class _PinPainter extends CustomPainter {
  const _PinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in the web's 28 x 36 box, scaled to fit.
    canvas.scale(size.width / 28, size.height / 36);
    final drop = Path()
      ..moveTo(14, 35)
      ..cubicTo(14, 35, 26.5, 20.8, 26.5, 13.5)
      ..cubicTo(26.5, 6.6, 20.9, 1, 14, 1)
      ..cubicTo(7.1, 1, 1.5, 6.6, 1.5, 13.5)
      ..cubicTo(1.5, 20.8, 14, 35, 14, 35)
      ..close();
    canvas
      ..drawShadow(drop, AppColors.accent, 4, false)
      ..drawPath(drop, Paint()..color = AppColors.accent)
      ..drawPath(
        drop,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.canvas,
      )
      ..drawCircle(
        const Offset(14, 13.5),
        5,
        Paint()..color = AppColors.canvas,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
