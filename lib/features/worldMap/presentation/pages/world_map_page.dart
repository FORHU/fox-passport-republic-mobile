import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/worldMap/data/repositories/store_repository.dart'
    show StoreRepository;
import 'package:flutter_template/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:flutter_template/shared/widgets/app_card.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

/// Nearby-places list, backed by the same data/domain/presentation stack as
/// `auth`/`home`/`profile`. This is a list-view placeholder for the map
/// itself — swap in a real map SDK (`flutter_map`, `mapbox_maps_flutter`)
/// against [WorldMapController]/[StoreRepository] once you've picked one;
/// nothing below this widget needs to change.
class WorldMapPage extends ConsumerWidget {
  const WorldMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(worldMapControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.ui.background,
      appBar: AppBar(
        title: Text(
          context.l10n.worldMap,
          style: TextStyle(color: AppColors.text.primary),
        ),
        backgroundColor: AppColors.ui.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(worldMapControllerProvider.notifier).fetchNearbyStores(),
        child: _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, WorldMapState state) {
    if (state.isLoading && state.stores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.stores.isEmpty) {
      return AppStateView(
        kind: AppStateKind.error,
        title: 'Could not load nearby places',
        message: state.error,
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(worldMapControllerProvider.notifier).fetchNearbyStores(),
      );
    }

    if (state.stores.isEmpty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: 'No nearby places',
        message: 'Nothing to show yet.',
      );
    }

    return ListView.separated(
      padding: AppSpacing.edgeInsetsMd,
      itemCount: state.stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final store = state.stores[index];
        return AppCard(
          child: Row(
            children: [
              Icon(Icons.place_outlined, color: AppColors.ink.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: TextStyle(
                        color: AppColors.text.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      store.address,
                      style: TextStyle(color: AppColors.text.secondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${store.distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(color: AppColors.text.secondary),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.status.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: TextStyle(color: AppColors.text.secondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
