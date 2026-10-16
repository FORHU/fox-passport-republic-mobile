import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:flutter_template/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:flutter_template/features/onboarding/domain/entities/onboarding_models.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';

// --- Providers ---

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(
    OnboardingRemoteDataSourceImpl(ref.watch(apiServiceProvider)),
  );
});

// --- State ---

/// The three screens of the web flow: Profile → Interests → Roles.
enum OnboardingStep { profile, intent, roles }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.profile,
    this.name = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.district = '',
    this.heldRoles = const [],
    this.pendingRoles = const [],
    this.revisions = const [],
    this.countries = const [],
    this.states = const [],
    this.statesFetched = false,
    this.cities = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.error,
  });

  final OnboardingStep step;
  final String name;
  final String country;
  final String state;
  final String city;
  final String district;

  /// Roles the user already holds (from `User.roleType`).
  final List<String> heldRoles;

  /// `roleType`s with an application under review.
  final List<String> pendingRoles;

  /// Applications an admin flagged for resubmission.
  final List<RoleRequestSummary> revisions;

  final List<GeoCountry> countries;
  final List<GeoState> states;
  final bool statesFetched;
  final List<String> cities;

  final bool isLoading;
  final bool isSaving;
  final String? error;

  // ── Derived ────────────────────────────────────────────────────────────

  bool get hasHeldRoles => heldRoles.isNotEmpty;

  /// Someone already committed to a role skips the "what brings you here" step.
  bool get hasCommittedRoles =>
      hasHeldRoles || pendingRoles.isNotEmpty || revisions.isNotEmpty;

  /// What still blocks Continue, named so the button can say why.
  List<String> get missing => [
        if (name.trim().isEmpty) 'display name',
        if (country.trim().isEmpty) 'country',
        if (city.trim().isEmpty) 'city',
      ];

  bool get profileComplete => missing.isEmpty;

  /// Barangay in the Philippines, district elsewhere.
  bool get isPhilippines =>
      RegExp(r'^philippines$', caseSensitive: false).hasMatch(country.trim());

  String get districtLabel => isPhilippines ? 'Barangay' : 'District';

  String? get countryCode {
    final c = country.trim().toLowerCase();
    if (c.isEmpty) return null;
    for (final item in countries) {
      if (item.name.toLowerCase() == c || item.code.toLowerCase() == c) {
        return item.code;
      }
    }
    return null;
  }

  bool get hasStates => states.isNotEmpty;

  String? get stateCode {
    final s = state.trim().toLowerCase();
    if (s.isEmpty) return null;
    for (final item in states) {
      if (item.name.toLowerCase() == s) return item.code;
    }
    return null;
  }

  /// A country without states lists its cities directly; so does a state the
  /// dataset doesn't know (typed in, or saved before these lists existed).
  String? get cityScope => hasStates ? stateCode : null;

  bool get cityReady =>
      countryCode != null &&
      statesFetched &&
      (!hasStates || state.trim().isNotEmpty);

  /// The journey shown in the stepper.
  List<OnboardingStep> get journey => hasCommittedRoles
      ? const [OnboardingStep.profile, OnboardingStep.roles]
      : OnboardingStep.values;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? name,
    String? country,
    String? state,
    String? city,
    String? district,
    List<String>? heldRoles,
    List<String>? pendingRoles,
    List<RoleRequestSummary>? revisions,
    List<GeoCountry>? countries,
    List<GeoState>? states,
    bool? statesFetched,
    List<String>? cities,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        name: name ?? this.name,
        country: country ?? this.country,
        state: state ?? this.state,
        city: city ?? this.city,
        district: district ?? this.district,
        heldRoles: heldRoles ?? this.heldRoles,
        pendingRoles: pendingRoles ?? this.pendingRoles,
        revisions: revisions ?? this.revisions,
        countries: countries ?? this.countries,
        states: states ?? this.states,
        statesFetched: statesFetched ?? this.statesFetched,
        cities: cities ?? this.cities,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        // Intentionally not `error ?? this.error`: passing null clears it.
        error: error,
      );

  @override
  List<Object?> get props => [
        step,
        name,
        country,
        state,
        city,
        district,
        heldRoles,
        pendingRoles,
        revisions,
        countries,
        states,
        statesFetched,
        cities,
        isLoading,
        isSaving,
        error,
      ];
}

// --- Controller ---

class OnboardingController extends Notifier<OnboardingState> {
  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);

  /// Organizer and investor aren't Foxers (neither supplies inventory) but are
  /// still roles this flow offers, so they count as ones the user holds.
  static final Set<String> _offeredRoles = {
    for (final r in roleCatalog) r.roleType,
  };

  @override
  OnboardingState build() {
    final user = ref.read(authControllerProvider).user;
    final held = [
      for (final r in user?.roleType ?? const <String>[])
        if (_offeredRoles.contains(r)) r,
    ];

    // Kick the loads off once `build` has returned its initial state.
    unawaited(Future.microtask(_load));

    return OnboardingState(
      step: held.isNotEmpty ? OnboardingStep.roles : OnboardingStep.profile,
      name: user?.name ?? '',
      heldRoles: held,
    );
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repo.fetchProfile(),
      _repo.fetchMyRoleRequests(),
      _repo.fetchCountries(),
    ]);

    final profile = results[0].fold(
      (_) => null,
      (v) => v as ProfileSeed,
    );
    final requests = results[1].fold(
      (_) => <RoleRequestSummary>[],
      (v) => v as List<RoleRequestSummary>,
    );
    final countries = results[2].fold(
      (_) => <GeoCountry>[],
      (v) => v as List<GeoCountry>,
    );
    final loadError = results[0].fold<String?>(
          (failure) => failure.message,
          (_) => null,
        ) ??
        results[1].fold<String?>(
          (failure) => failure.message,
          (_) => null,
        ) ??
        results[2].fold<String?>(
          (failure) => failure.message,
          (_) => null,
        );

    final pending = [
      for (final r in requests)
        if (r.isPending) r.roleType,
    ];
    final revisions = [
      for (final r in requests)
        if (r.needsRevision) r,
    ];

    state = state.copyWith(
      // Prefer what the server has over the cached session name.
      name: (profile?.name.isNotEmpty ?? false) ? profile!.name : state.name,
      country: profile?.country,
      state: profile?.state,
      city: profile?.city,
      district: profile?.district,
      pendingRoles: pending,
      revisions: revisions,
      countries: countries,
      isLoading: false,
      error: loadError == null || loadError.isEmpty ? null : loadError,
      step: (pending.isNotEmpty || revisions.isNotEmpty)
          ? OnboardingStep.roles
          : state.step,
    );

    // A saved address needs its state and city lists to show as selected.
    if (state.countryCode != null) await _loadStates();
  }

  // ── Profile fields ───────────────────────────────────────────────────

  void setName(String value) => state = state.copyWith(name: value);

  void setDistrict(String value) => state = state.copyWith(district: value);

  Future<void> selectCountry(String name) async {
    state = state.copyWith(
      country: name,
      state: '',
      city: '',
      states: const [],
      statesFetched: false,
      cities: const [],
    );
    if (state.countryCode != null) await _loadStates();
  }

  Future<void> selectState(String name) async {
    state = state.copyWith(state: name, city: '', cities: const []);
    await _loadCities();
  }

  void selectCity(String name) => state = state.copyWith(city: name);

  Future<void> _loadStates() async {
    final code = state.countryCode;
    if (code == null) return;
    final country = state.country;

    final result = await _repo.fetchStates(code);
    // The user may have picked another country while this was in flight.
    if (state.country != country) return;

    state = state.copyWith(
      states: result.fold((_) => const <GeoState>[], (v) => v),
      statesFetched: true,
      error: result.fold(
        (failure) => failure.message.isEmpty
            ? "Couldn't load states. Please try again."
            : failure.message,
        (_) => null,
      ),
    );
    await _loadCities();
  }

  Future<void> _loadCities() async {
    final code = state.countryCode;
    if (code == null || !state.cityReady) return;
    final country = state.country;
    final region = state.state;

    final result = await _repo.fetchCities(code, stateCode: state.cityScope);
    if (state.country != country || state.state != region) return;

    state = state.copyWith(
      cities: result.fold((_) => const <String>[], (v) => v),
      error: result.fold(
        (failure) => failure.message.isEmpty
            ? "Couldn't load cities. Please try again."
            : failure.message,
        (_) => null,
      ),
    );
  }

  // ── Navigation & saving ───────────────────────────────────────────────

  void goTo(OnboardingStep step) => state = state.copyWith(step: step);

  void backFromRoles() => goTo(
        state.hasCommittedRoles
            ? OnboardingStep.profile
            : OnboardingStep.intent,
      );

  /// Saves the profile, then moves on. Stays on the step if the save fails —
  /// moving on would let the user believe it was saved.
  Future<bool> saveProfileAndContinue() async {
    if (!state.profileComplete || state.isSaving) return false;
    state = state.copyWith(isSaving: true);

    final result = await _repo.saveProfile(
      name: state.name.trim(),
      country: state.country.trim(),
      state: state.state.trim(),
      city: state.city.trim(),
      district: state.district.trim(),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: failure.message.isEmpty
              ? "Couldn't save your profile. Please try again."
              : failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isSaving: false,
          step: state.hasCommittedRoles
              ? OnboardingStep.roles
              : OnboardingStep.intent,
        );
        return true;
      },
    );
  }
}

final NotifierProvider<OnboardingController, OnboardingState>
    onboardingControllerProvider =
    NotifierProvider.autoDispose<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
