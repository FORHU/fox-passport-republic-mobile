import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_update.dart';
import 'package:flutter_template/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';

// --- Dependency wiring (Riverpod providers) ---

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remote = ProfileRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return ProfileRepositoryImpl(remote);
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
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

  /// Saves the changed parts of the profile. Returns null on success, else
  /// the message to show. On success the session user takes the new name,
  /// username and photo too, so Settings and the Passport show them at once.
  Future<String?> updateProfile(ProfileUpdate update) async {
    final result =
        await ref.read(profileRepositoryProvider).updateProfile(update);
    return result.fold((failure) => failure.message, (_) {
      ref.read(authControllerProvider.notifier).setSessionProfile(
            name: update.name?.trim(),
            username: update.username?.trim(),
            imageUrl: update.imageUrl,
          );
      // The public page shows these too, so it loads them again.
      final id = ref.read(currentUserIdProvider);
      if (id != null) ref.invalidate(citizenProfileProvider(id));
      unawaited(fetchProfile());
      return null;
    });
  }

  /// Uploads a new profile photo and makes it the profile's. Returns null on
  /// success, else the message to show.
  Future<String?> changePhoto(PickedPhoto photo) async {
    final uploaded =
        await ref.read(profileRepositoryProvider).uploadPhoto(photo);
    final url = uploaded.fold<String?>((_) => null, (url) => url);
    if (url == null) return uploaded.fold((f) => f.message, (_) => '');
    return updateProfile(ProfileUpdate(imageUrl: url));
  }

  /// Returns null on success, else the message to show.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ref.read(profileRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Deletes the account and ends the session. Returns null on success, else
  /// the message to show.
  Future<String?> deleteAccount(String password) async {
    final result =
        await ref.read(profileRepositoryProvider).deleteAccount(password);
    return result.fold((failure) => failure.message, (_) {
      // The account is gone, so there is no session to sign out of on the
      // server: clear it here and the router sends them to the start.
      unawaited(ref.read(authControllerProvider.notifier).onUnauthenticated());
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
