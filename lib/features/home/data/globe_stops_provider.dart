import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/utils/logger.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/home/domain/globe_stops_builder.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart';

/// The pins and callout cards for the home globe: where events are happening,
/// busiest first. Both calls are public, so the globe works signed-out too.
///
/// Failures resolve to an empty list rather than an error: a globe without pins
/// is still a good hero, and the rest of Home must not depend on it.
final FutureProvider<List<GlobeStop>> globeStopsProvider =
    FutureProvider.autoDispose<List<GlobeStop>>((ref) async {
  final api = ref.watch(apiServiceProvider);

  List<Map<String, dynamic>> rows(dynamic body, String key) {
    final raw = body is Map ? (body[key] ?? body['data']) : null;
    return raw is List
        ? [
            for (final item in raw)
              if (item is Map) item.cast<String, dynamic>(),
          ]
        : const [];
  }

  try {
    final results = await Future.wait([
      api.get(ApiEndpoints.eventsBrowse, query: {'limit': 60}),
      api.get(ApiEndpoints.venues, query: {'limit': 80}),
    ]);
    return buildGlobeStops(
      events: rows(results[0], 'data'),
      venues: rows(results[1], 'venues'),
    );
  } on Object catch (e) {
    appLogger.w('Globe stops unavailable: $e');
    return const [];
  }
});
