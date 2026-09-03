import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:flutter_template/features/worldMap/data/repositories/store_repository.dart';
import 'package:flutter_template/features/worldMap/domain/entities/store_entity.dart';
import 'package:flutter_template/features/worldMap/domain/usecases/get_nearby_stores_usecase.dart';

// --- Dependency wiring ---

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final remote = StoreRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return StoreRepositoryImpl(remote);
});

final getNearbyStoresUseCaseProvider = Provider<GetNearbyStoresUseCase>(
  (ref) => GetNearbyStoresUseCase(ref.watch(storeRepositoryProvider)),
);

// --- State ---

class WorldMapState extends Equatable {
  const WorldMapState({
    this.isLoading = false,
    this.stores = const [],
    this.error,
  });

  final bool isLoading;
  final List<StoreEntity> stores;
  final String? error;

  WorldMapState copyWith({
    bool? isLoading,
    List<StoreEntity>? stores,
    String? error,
  }) => WorldMapState(
    isLoading: isLoading ?? this.isLoading,
    stores: stores ?? this.stores,
    error: error,
  );

  @override
  List<Object?> get props => [isLoading, stores, error];
}

// --- Controller ---

/// Drives the world-map list view. Replace/extend once a real map SDK
/// (e.g. `flutter_map`, `mapbox_maps_flutter`) is wired in — the domain and
/// data layers below are already SDK-agnostic.
class WorldMapController extends Notifier<WorldMapState> {
  @override
  WorldMapState build() {
    unawaited(Future.microtask(fetchNearbyStores));
    return const WorldMapState(isLoading: true);
  }

  Future<void> fetchNearbyStores() async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(getNearbyStoresUseCaseProvider)();
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (stores) => state = WorldMapState(stores: stores),
    );
  }
}

final worldMapControllerProvider =
    NotifierProvider<WorldMapController, WorldMapState>(
      WorldMapController.new,
    );
