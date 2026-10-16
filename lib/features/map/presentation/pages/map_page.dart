import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/data/globe_stops_provider.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Map: every place with events, pinned on a globe you can turn and pinch.
/// Under it, the same places as a row of cards; picking one centres the globe
/// on it.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GlobeStop? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stops = ref.watch(globeStopsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.mapTitle,
                  style: AppTypography.display(size: 28),
                ),
              ),
            ),
            Expanded(
              child: stops.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (_, __) => AppStateView(
                  kind: AppStateKind.error,
                  title: l10n.apiLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(globeStopsProvider),
                ),
                data: (list) => _Body(
                  stops: list,
                  selected: _selected,
                  onSelect: (s) => setState(() => _selected = s),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.stops,
    required this.selected,
    required this.onSelect,
  });

  final List<GlobeStop> stops;
  final GlobeStop? selected;
  final ValueChanged<GlobeStop> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pick = selected;

    return Column(
      children: [
        Expanded(
          child: RotatingGlobe(
            interactive: true,
            stops: stops,
            maxCards: 0,
            nightLights: false,
            startLat: pick?.lat ?? 14,
            startLng: pick?.lng ?? 121,
            zoom: pick == null ? null : 3.2,
            onStopTap: (city) => context.go(
              RouteNames.searchFor('events', city: city),
            ),
          ),
        ),
        if (stops.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.mapEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(),
                ),
                TextButton(
                  onPressed: () => context.go(RouteNames.searchFor('events')),
                  child: Text(l10n.mapEmptyAction),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              scrollDirection: Axis.horizontal,
              itemCount: stops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _PlaceCard(
                stop: stops[i],
                selected: identical(stops[i], pick),
                onTap: () => onSelect(stops[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.stop,
    required this.selected,
    required this.onTap,
  });

  final GlobeStop stop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: 236,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.brSm,
                      child: NetworkImageBox(
                        url: stop.imageUrl ?? '',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.city.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(color: AppColors.accent),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stop.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.display(size: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.mapEventCount(stop.eventCount),
                      style: AppTypography.label(),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.go(
                        RouteNames.searchFor('events', city: stop.city),
                      ),
                      child: Text(
                        l10n.mapViewEvents,
                        style: AppTypography.body(
                          color: AppColors.accent,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
