import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/shared/location/device_locator.dart';

/// The steps of the studio, in order.
enum StudioStep { basics, location, photos, details, pricing, review }

/// Where the studio stands while a host fills in a venue.
class VenueStudioState {
  const VenueStudioState({
    this.draft = const VenueDraft(),
    this.step = StudioStep.basics,
    this.loading = false,
    this.loadFailed = false,
    this.saving = false,
    this.uploading = false,
    this.error,
    this.live = false,
    this.neighbours = const [],
    this.policies = const [],
    this.errorDetail,
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.countryCode,
    this.stateCode,
    this.locating = false,
    this.locateProblem,
  });

  final VenueDraft draft;
  final StudioStep step;

  /// Reading the venue to edit.
  final bool loading;
  final bool loadFailed;
  final bool saving;
  final bool uploading;

  /// Why the last save or upload did not work, in words for the host.
  final String? error;

  /// The venue being edited is already live, so saving keeps it live.
  final bool live;
  final List<VenueBoundary> neighbours;
  final List<CancellationPolicyOption> policies;

  /// What the server said when the last upload or save was refused.
  final String? errorDetail;

  /// The dropdowns for the venue's place, narrowing country to state to city.
  final List<PlaceOption> countries;
  final List<PlaceOption> states;
  final List<String> cities;
  final String? countryCode;
  final String? stateCode;

  /// Finding the phone's position for the pin.
  final bool locating;

  /// Why that did not work: `denied`, `off` or `failed`.
  final String? locateProblem;

  /// Names of the venues whose service area this one runs into.
  List<String> get overlapping {
    final ring = draft.boundary;
    if (ring == null) return const [];
    return [
      for (final n in neighbours)
        if (ringsOverlap(ring, n.ring)) n.name,
    ];
  }

  bool get canSubmit => draft.readyToSubmit && overlapping.isEmpty;

  VenueStudioState copyWith({
    VenueDraft? draft,
    StudioStep? step,
    bool? loading,
    bool? loadFailed,
    bool? saving,
    bool? uploading,
    String? error,
    bool clearError = false,
    bool? live,
    List<VenueBoundary>? neighbours,
    List<CancellationPolicyOption>? policies,
    String? errorDetail,
    List<PlaceOption>? countries,
    List<PlaceOption>? states,
    List<String>? cities,
    String? countryCode,
    String? stateCode,
    bool clearStateCode = false,
    bool? locating,
    String? locateProblem,
    bool clearLocateProblem = false,
  }) =>
      VenueStudioState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        loading: loading ?? this.loading,
        loadFailed: loadFailed ?? this.loadFailed,
        saving: saving ?? this.saving,
        uploading: uploading ?? this.uploading,
        error: clearError ? null : error ?? this.error,
        live: live ?? this.live,
        neighbours: neighbours ?? this.neighbours,
        policies: policies ?? this.policies,
        errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
        countries: countries ?? this.countries,
        states: states ?? this.states,
        cities: cities ?? this.cities,
        countryCode: countryCode ?? this.countryCode,
        stateCode: clearStateCode ? null : stateCode ?? this.stateCode,
        locating: locating ?? this.locating,
        locateProblem:
            clearLocateProblem ? null : locateProblem ?? this.locateProblem,
      );
}

/// Drives the venue studio: a new venue when [venueId] is null, otherwise the
/// saved venue loaded to edit.
class VenueStudioController extends Notifier<VenueStudioState> {
  VenueStudioController(this.venueId);

  final String? venueId;

  @override
  VenueStudioState build() {
    unawaited(Future.microtask(_load));
    return VenueStudioState(loading: venueId != null);
  }

  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  Future<void> _load() async {
    // The map, policies and place lists are extras: the studio works without
    // them.
    unawaited(_loadNeighbours());
    unawaited(_loadPolicies());
    final countries = _loadCountries();
    final id = venueId;
    if (id == null) return;
    try {
      final detail = await _repo.venueDetail(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        draft: detail.draft,
        live: detail.isLive,
        loading: false,
      );
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, loadFailed: true);
      return;
    }
    await countries;
    if (!ref.mounted) return;
    await _matchSavedPlace();
  }

  Future<void> _loadCountries() async {
    try {
      final all = await _repo.countries();
      if (!ref.mounted) return;
      state = state.copyWith(countries: all);
    } on Object {
      // The country can still be typed by name.
    }
  }

  /// Finds the saved venue's country and state in the lists, so the dropdowns
  /// narrow down to its city.
  Future<void> _matchSavedPlace() async {
    final country = state.countries
        .where(
          (c) => c.name.toLowerCase() == state.draft.country.toLowerCase(),
        )
        .firstOrNull;
    if (country == null) return;
    state = state.copyWith(countryCode: country.code);
    await _loadStates(country.code, keepState: state.draft.state);
  }

  /// Loads a country's states and, when it has none or one is already chosen,
  /// its cities.
  Future<void> _loadStates(String countryCode, {String? keepState}) async {
    try {
      final states = await _repo.states(countryCode);
      if (!ref.mounted) return;
      final kept = states
          .where((s) => s.name.toLowerCase() == keepState?.toLowerCase())
          .firstOrNull;
      state = state.copyWith(
        states: states,
        stateCode: kept?.code,
        clearStateCode: kept == null,
      );
      if (states.isEmpty || kept != null) {
        await _loadCities(countryCode, kept?.code);
      }
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(states: const <PlaceOption>[]);
      await _loadCities(countryCode, null);
    }
  }

  Future<void> _loadCities(String countryCode, String? stateCode) async {
    try {
      final all = await _repo.cities(countryCode, stateCode: stateCode);
      if (!ref.mounted) return;
      state = state.copyWith(cities: all);
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(cities: const <String>[]);
    }
  }

  /// Chooses a country: the state and city start over.
  Future<void> pickCountry(PlaceOption country) async {
    state = state.copyWith(
      draft: state.draft.copyWith(
        country: country.name,
        state: '',
        city: '',
      ),
      countryCode: country.code,
      clearStateCode: true,
      states: const <PlaceOption>[],
      cities: const <String>[],
      clearError: true,
    );
    await _loadStates(country.code);
  }

  Future<void> pickState(PlaceOption chosen) async {
    state = state.copyWith(
      draft: state.draft.copyWith(state: chosen.name, city: ''),
      stateCode: chosen.code,
      cities: const <String>[],
      clearError: true,
    );
    final code = state.countryCode;
    if (code != null) await _loadCities(code, chosen.code);
  }

  void pickCity(String city) => edit((d) => d.copyWith(city: city));

  /// Puts the pin where the phone is and fills in the town and country.
  Future<void> useMyLocation() async {
    if (state.locating) return;
    state = state.copyWith(locating: true, clearLocateProblem: true);
    final locator = ref.read(deviceLocatorProvider);
    final found = await locator.locate();
    if (!ref.mounted) return;
    if (!found.isOk) {
      state = state.copyWith(
        locating: false,
        locateProblem: switch (found.outcome) {
          LocateOutcome.denied => 'denied',
          LocateOutcome.serviceOff => 'off',
          _ => 'failed',
        },
      );
      return;
    }
    final here = (lat: found.lat!, lng: found.lng!);
    state = state.copyWith(draft: state.draft.copyWith(center: here));

    final place = await locator.placeAt(here.lat, here.lng);
    if (!ref.mounted) return;
    final code = place.countryCode?.toUpperCase();
    final country = code == null
        ? null
        : state.countries
            .where((c) => c.code.toUpperCase() == code)
            .firstOrNull;
    if (country != null && country.code != state.countryCode) {
      await pickCountry(country);
      if (!ref.mounted) return;
    }
    if (place.city != null) pickCity(place.city!);
    state = state.copyWith(locating: false);
  }

  Future<void> _loadNeighbours() async {
    try {
      final all = await _repo.neighbourBoundaries(excludeId: venueId);
      if (!ref.mounted) return;
      state = state.copyWith(neighbours: all);
    } on Object {
      // The API still refuses an overlap when the host saves.
    }
  }

  Future<void> _loadPolicies() async {
    try {
      final all = await _repo.cancellationPolicies();
      if (!ref.mounted) return;
      state = state.copyWith(policies: all);
    } on Object {
      // Optional.
    }
  }

  void edit(VenueDraft Function(VenueDraft draft) change) {
    state = state.copyWith(draft: change(state.draft), clearError: true);
  }

  void goTo(StudioStep step) => state = state.copyWith(step: step);

  void next() {
    final i = state.step.index;
    if (i < StudioStep.values.length - 1) {
      goTo(StudioStep.values[i + 1]);
    }
  }

  void back() {
    final i = state.step.index;
    if (i > 0) goTo(StudioStep.values[i - 1]);
  }

  /// Uploads a photo and adds it, up to five.
  Future<void> addPhoto(PickedPhoto photo) async {
    if (state.draft.photos.length >= 5) return;
    state = state.copyWith(uploading: true, clearError: true);
    try {
      final uploaded = await _repo.uploadVenuePhoto(photo);
      if (!ref.mounted) return;
      state = state.copyWith(
        uploading: false,
        draft: state.draft.copyWith(
          photos: [...state.draft.photos, uploaded],
        ),
      );
    } on Object catch (e) {
      // Say why when the server did: a storage problem looks the same as a
      // bad photo otherwise.
      if (!ref.mounted) return;
      state = state.copyWith(
        uploading: false,
        error: 'photo',
        errorDetail: e is AppException ? e.message : null,
      );
    }
  }

  void removePhoto(String fileId) {
    edit(
      (d) => d.copyWith(
        photos: [
          for (final p in d.photos)
            if (p.fileId != fileId) p,
        ],
      ),
    );
  }

  /// Saves the venue. [submit] sends a new or draft venue for review; a live
  /// venue just keeps its changes. Returns whether it worked.
  Future<bool> save({required bool submit}) async {
    if (state.saving) return false;
    if (submit && !state.canSubmit) return false;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final id = venueId;
      if (id == null) {
        await _repo.createVenue(state.draft, submit: submit);
      } else {
        await _repo.updateVenue(
          id,
          state.draft,
          live: state.live,
          submit: submit,
        );
      }
      // It was saved even if the screen has gone.
      if (!ref.mounted) return true;
      state = state.copyWith(saving: false);
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        saving: false,
        error: '$e'.contains('overlaps') || '$e'.contains('409')
            ? 'overlap'
            : 'save',
      );
      return false;
    }
  }
}

// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final venueStudioProvider = NotifierProvider.autoDispose
    .family<VenueStudioController, VenueStudioState, String?>(
  VenueStudioController.new,
);
