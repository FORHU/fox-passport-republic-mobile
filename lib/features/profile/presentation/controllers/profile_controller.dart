import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutter_template/features/profile/domain/usecases/update_profile_name_usecase.dart';

// --- Dependency wiring (Riverpod providers) ---

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remote = ProfileRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return ProfileRepositoryImpl(remote);
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final updateProfileNameUseCaseProvider = Provider<UpdateProfileNameUseCase>(
  (ref) => UpdateProfileNameUseCase(ref.watch(profileRepositoryProvider)),
);

// --- State ---

class ProfileState extends Equatable {
  const ProfileState({this.isLoading = false, this.profile, this.error});

  final bool isLoading;
  final ProfileEntity? profile;
  final String? error;

  ProfileState copyWith({
    bool? isLoading,
    ProfileEntity? profile,
    String? error,
  }) =>
      ProfileState(
        isLoading: isLoading ?? this.isLoading,
        profile: profile ?? this.profile,
        // Intentionally not `error ?? this.error`: passing null clears it.
        error: error,
      );

  @override
  List<Object?> get props => [isLoading, profile, error];
}

// --- Controller ---

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // A different account gets its own profile, not the previous one's.
    ref.watch(currentUserIdProvider);
    unawaited(Future.microtask(fetchProfile));
    return const ProfileState(isLoading: true);
  }

  /// Saves a new display name. Returns null on success, else the message to
  /// show. On success the session user is renamed too, so Settings and the
  /// Passport show the new name at once.
  Future<String?> updateName(String name) async {
    final result = await ref.read(updateProfileNameUseCaseProvider)(name);
    return result.fold((failure) => failure.message, (_) {
      ref.read(authControllerProvider.notifier).setSessionName(name.trim());
      unawaited(fetchProfile());
      return null;
    });
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true);

    final result = await ref.read(getProfileUseCaseProvider)();

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (profile) => state = ProfileState(profile: profile),
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);
