import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// A map where the host taps to drop the venue's pin. Around the pin it draws
/// the service area, and in a warning colour the areas of venues nearby. When
/// the pin is set from elsewhere, such as the phone's position, the map moves
/// to it.
class ServiceAreaMap extends StatefulWidget {
  const ServiceAreaMap({
    required this.center,
    required this.radiusMeters,
    required this.neighbours,
    required this.onPin,
    this.mapboxToken,
    this.tileProvider,
    super.key,
  });

  final GeoPoint? center;
  final double radiusMeters;
  final List<VenueBoundary> neighbours;
  final ValueChanged<GeoPoint> onPin;

  /// The Mapbox public token; the app's configured one unless a test sets it.
  @visibleForTesting
  final String? mapboxToken;

  /// Where the tiles come from; the network unless a test swaps it.
  @visibleForTesting
  final TileProvider? tileProvider;

  @override
  State<ServiceAreaMap> createState() => _ServiceAreaMapState();
}

class _ServiceAreaMapState extends State<ServiceAreaMap> {
  // Manila: somewhere to start before the host has placed a pin.
  static const _start = LatLng(14.5995, 120.9842);

  final _controller = MapController();
  bool _ready = false;

  static String _configuredToken() {
    try {
      return AppConfig.instance.mapboxToken;
    } on Object {
      return '';
    }
  }

  static List<LatLng> _points(List<List<double>> ring) => [
        for (final p in ring) LatLng(p[1], p[0]),
      ];

  @override
  void didUpdateWidget(ServiceAreaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pin = widget.center;
    // A tap already shows under the finger; only a pin that landed out of
    // view (the phone's position) needs the map brought to it.
    if (_ready && pin != null && pin != oldWidget.center) {
      final camera = _controller.camera;
      final point = LatLng(pin.lat, pin.lng);
      if (!camera.visibleBounds.contains(point)) {
        _controller.move(point, camera.zoom < 13 ? 15 : camera.zoom);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = (widget.mapboxToken ?? _configuredToken()).trim();
    final pin = widget.center;
    if (token.isEmpty) {
      return _Frame(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.studioMapNeedsToken,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return _Frame(
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: pin == null ? _start : LatLng(pin.lat, pin.lng),
          initialZoom: pin == null ? 11 : 15,
          minZoom: 3,
          maxZoom: 18,
          backgroundColor: AppColors.surface,
          onMapReady: () => _ready = true,
          onTap: (_, point) =>
              widget.onPin((lat: point.latitude, lng: point.longitude)),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/'
                'tiles/256/{z}/{x}/{y}{r}?access_token=$token',
            userAgentPackageName: 'com.example.flutter_template',
            retinaMode: RetinaMode.isHighDensity(context),
            tileProvider: widget.tileProvider,
          ),
          PolygonLayer(
            polygons: [
              for (final n in widget.neighbours)
                Polygon(
                  points: _points(n.ring),
                  color: AppColors.warning.withValues(alpha: 0.18),
                  borderColor: AppColors.warning,
                  borderStrokeWidth: 1.5,
                ),
              if (pin != null)
                Polygon(
                  points: _points(circlePolygon(pin, widget.radiusMeters)),
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderColor: AppColors.accent,
                  borderStrokeWidth: 2,
                ),
            ],
          ),
          if (pin != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(pin.lat, pin.lng),
                  width: 36,
                  height: 44,
                  // The tip of the pin sits on the point.
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 40,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      );
}
