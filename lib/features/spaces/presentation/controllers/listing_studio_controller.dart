import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/listing_draft.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';

/// Which listing the studio is for: a kind, and the id to edit (null to add).
typedef ListingTarget = ({ProviderKind kind, String? id});

/// Where the form stands while a provider fills in a service or gear.
class ListingStudioState {
  const ListingStudioState({
    this.draft = const ListingDraft(),
    this.loading = false,
    this.loadFailed = false,
    this.live = false,
    this.saving = false,
    this.uploading = false,
    this.error,
    this.errorDetail,
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.countryCode,
    this.stateCode,
    this.locating = false,
    this.locateProblem,
  });

  final ListingDraft draft;
  final bool loading;
  final bool loadFailed;

  /// Already live: it keeps its changes and never goes back to draft.
  final bool live;
  final bool saving;
  final bool uploading;

  /// `photo` or `save`, or null.
  final String? error;
  final String? errorDetail;

  final List<PlaceOption> countries;
  final List<PlaceOption> states;
  final List<String> cities;
  final String? countryCode;
  final String? stateCode;
  final bool locating;

  /// `denied`, `off` or `failed`, or null.
  final String? locateProblem;

  ListingStudioState copyWith({
    ListingDraft? draft,
    bool? loading,
    bool? loadFailed,
    bool? live,
    bool? saving,
    bool? uploading,
    String? error,
    String? errorDetail,
    bool clearError = false,
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
      ListingStudioState(
        draft: draft ?? this.draft,
        loading: loading ?? this.loading,
        loadFailed: loadFailed ?? this.loadFailed,
        live: live ?? this.live,
        saving: saving ?? this.saving,
        uploading: uploading ?? this.uploading,
        error: clearError ? null : error ?? this.error,
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

class ListingStudioController extends Notifier<ListingStudioState> {
  ListingStudioController(this.target);

  final ListingTarget target;

  @override
  ListingStudioState build() {
    unawaited(Future.microtask(_load));
    return ListingStudioState(loading: target.id != null);
  }

  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  Future<void> _load() async {
    final countries = _loadCountries();
    final id = target.id;
    if (id == null) return;
    try {
      final saved = await _repo.listingDetail(target.kind, id);
      if (!ref.mounted) return;
      state = state.copyWith(
        draft: saved.draft,
        live: const {'available', 'reserved'}.contains(saved.status),
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

  /// Finds the saved country and state in the lists, so the dropdowns narrow
  /// down to its city.
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

  void edit(ListingDraft Function(ListingDraft draft) change) {
    state = state.copyWith(draft: change(state.draft), clearError: true);
  }

  /// Chooses a country: the state and city start over.
  Future<void> pickCountry(PlaceOption country) async {
    state = state.copyWith(
      draft: state.draft.copyWith(country: country.name, state: '', city: ''),
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

  /// Fills in the town and country from where the phone is.
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
    edit((d) => d.copyWith(lat: found.lat, lng: found.lng));

    final place = await locator.placeAt(found.lat!, found.lng!);
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

  /// Uploads a photo and adds it, up to five. Only when adding: the API
  /// cannot change a saved listing's photos.
  Future<void> addPhoto(PickedPhoto photo) async {
    if (state.draft.photos.length >= 5) return;
    state = state.copyWith(uploading: true, clearError: true);
    try {
      final uploaded = await _repo.uploadVenuePhoto(photo);
      if (!ref.mounted) return;
      state = state.copyWith(
        uploading: false,
        draft: state.draft.copyWith(photos: [...state.draft.photos, uploaded]),
      );
    } on Object catch (e) {
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

  /// Saves it. [submit] sends a new or draft listing for review; a live one
  /// just keeps its changes. Returns whether it worked.
  Future<bool> save({required bool submit}) async {
    if (state.saving || !state.draft.isComplete(target.kind)) return false;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final id = target.id;
      if (id == null) {
        await _repo.createListing(target.kind, state.draft, submit: submit);
      } else {
        await _repo.updateListing(
          target.kind,
          id,
          state.draft,
          live: state.live,
          submit: submit,
        );
      }
      if (!ref.mounted) return true;
      state = state.copyWith(saving: false);
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        saving: false,
        error: 'save',
        errorDetail: e is AppException ? e.message : null,
      );
      return false;
    }
  }
}

// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final listingStudioProvider = NotifierProvider.autoDispose
    .family<ListingStudioController, ListingStudioState, ListingTarget>(
  ListingStudioController.new,
);
