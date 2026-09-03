import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/home/data/datasources/home_remote_datasource.dart';
import 'package:flutter_template/features/home/data/repositories/home_repository.dart';
import 'package:flutter_template/features/home/domain/entities/home_item.dart';
import 'package:flutter_template/features/home/domain/usecases/get_home_items_usecase.dart';

// --- Dependency wiring (Riverpod providers) ---

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final remote = HomeRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return HomeRepositoryImpl(remote);
});

final getHomeItemsUseCaseProvider = Provider<GetHomeItemsUseCase>(
  (ref) => GetHomeItemsUseCase(ref.watch(homeRepositoryProvider)),
);

// --- State ---

class HomeState extends Equatable {
  const HomeState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  final bool isLoading;
  final List<HomeItem> items;
  final String? error;

  HomeState copyWith({bool? isLoading, List<HomeItem>? items, String? error}) =>
      HomeState(
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        // Intentionally not `error ?? this.error`: passing null clears it.
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, items, error];
}

// --- Controller ---

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    unawaited(Future.microtask(fetchItems));
    return const HomeState(isLoading: true);
  }

  Future<void> fetchItems() async {
    state = state.copyWith(isLoading: true);

    final result = await ref.read(getHomeItemsUseCaseProvider)();

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (items) => state = HomeState(items: items),
    );
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
