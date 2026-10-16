import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/home/data/globe_stops_provider.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The map view of Search: every place with events on a globe you can turn and
/// pinch, and under it the same places as a row of cards. Choosing a place
/// centres the globe; tapping a pin or "View events" calls [onViewCity].
class PlacesGlobe extends ConsumerStatefulWidget {
  const PlacesGlobe({required this.onViewCity, super.key});

  /// Show the events in this city (the list view, filtered).
  final ValueChanged<String> onViewCity;

  @override
  ConsumerState<PlacesGlobe> createState() => _PlacesGlobeState();
}

class _PlacesGlobeState extends ConsumerState<PlacesGlobe> {
  GlobeStop? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stops = ref.watch(globeStopsProvider);

    return stops.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (_, __) => AppStateView(
        kind: AppStateKind.error,
        title: l10n.apiLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(globeStopsProvider),
      ),
      data: (list) {
        final pick = _selected;
        return Column(
          children: [
            Expanded(
              child: RotatingGlobe(
                interactive: true,
                stops: list,
                maxCards: 0,
                nightLights: false,
                startLat: pick?.lat ?? 14,
                startLng: pick?.lng ?? 121,
                zoom: pick == null ? null : 3.2,
                onStopTap: widget.onViewCity,
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.mapEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(),
                ),
              )
            else
              SizedBox(
                height: 132,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _PlaceCard(
                    stop: list[i],
                    selected: identical(list[i], pick),
                    onTap: () => setState(() => _selected = list[i]),
                    onView: () => widget.onViewCity(list[i].city),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.stop,
    required this.selected,
    required this.onTap,
    required this.onView,
  });

  final GlobeStop stop;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onView;

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
                      onTap: onView,
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
