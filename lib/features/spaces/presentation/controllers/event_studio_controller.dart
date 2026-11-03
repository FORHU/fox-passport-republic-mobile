import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/shared/location/device_locator.dart';

/// The steps of the event studio, in order.
enum EventStep { basics, location, photos, package, review }

/// What came of adding something to the package.
enum AddResult {
  added,

  /// It is in the package already.
  duplicate,

  /// There is a venue already; only one is allowed.
  alreadyHasVenue,

  /// The host's affiliation with that venue is still waiting for an answer.
  venuePending,

  /// The host has no affiliation with that venue; they must apply first.
  venueNotApplied,
}

/// What came of saving.
enum SaveOutcome {
  /// Saved as a draft, or saved changes to an event that is not a draft.
  saved,

  /// Sent for review.
  submitted,

  /// Saved, but the API refused some package items, so nothing was submitted.
  partial,

  /// Not saved because something needed is missing.
  blocked,

  /// The API refused or could not be reached.
  failed,
}

/// Where the event studio stands while a host builds an event.
class EventStudioState {
  const EventStudioState({
    this.draft = const EventDraft(),
    this.baseline = const [],
    this.step = EventStep.basics,
    this.loading = false,
    this.loadFailed = false,
    this.saving = false,
    this.uploading = false,
    this.error,
    this.errorDetail,
    this.eventId,
    this.status,
    this.problems = const [],
    this.policies = const [],
    this.countries = const [],
    this.states = const [],
    this.cities = const [],
    this.countryCode,
    this.stateCode,
    this.locating = false,
    this.locateProblem,
    this.ownedVenueIds = const {},
    this.affiliations = const {},
  });

  final EventDraft draft;

  /// The package as last saved, to tell what the host has changed since.
  final List<PackageItem> baseline;
  final EventStep step;
  final bool loading;
  final bool loadFailed;
  final bool saving;
  final bool uploading;

  /// `photo`, `title` or `save`: what went wrong last.
  final String? error;

  /// What the server said, when it said something.
  final String? errorDetail;

  /// The saved event's id, once it has one.
  final String? eventId;

  /// The saved event's status: `draft`, `pending`, `published`, ...
  final String? status;

  /// Package items the API would not take, from the last save.
  final List<PackageProblem> problems;
  final List<CancellationPolicyOption> policies;
  final List<PlaceOption> countries;
  final List<PlaceOption> states;
  final List<String> cities;
  final String? countryCode;
  final String? stateCode;
  final bool locating;

  /// `denied`, `off` or `failed`.
  final String? locateProblem;

  /// The venues the host runs, so they can be put in an event outright.
  final Set<String> ownedVenueIds;

  /// The host's affiliations with other people's venues.
  final Map<String, VenueAccess> affiliations;

  bool get isNew => eventId == null;

  /// Only a draft (or an event not saved yet) can be sent for review.
  bool get canSubmit =>
      draft.readyToSubmit && (eventId == null || status == 'draft');

  /// Whether the host may put this venue in the event.
  VenueAccess accessFor(String venueId) {
    if (ownedVenueIds.contains(venueId)) return VenueAccess.approved;
    return affiliations[venueId] ?? VenueAccess.none;
  }

  EventStudioState copyWith({
    EventDraft? draft,
    List<PackageItem>? baseline,
    EventStep? step,
    bool? loading,
    bool? loadFailed,
    bool? saving,
    bool? uploading,
    String? error,
    String? errorDetail,
    bool clearError = false,
    String? eventId,
    String? status,
    List<PackageProblem>? problems,
    List<CancellationPolicyOption>? policies,
    List<PlaceOption>? countries,
    List<PlaceOption>? states,
    List<String>? cities,
    String? countryCode,
    String? stateCode,
    bool clearStateCode = false,
    bool? locating,
    String? locateProblem,
    bool clearLocateProblem = false,
    Set<String>? ownedVenueIds,
    Map<String, VenueAccess>? affiliations,
  }) =>
      EventStudioState(
        draft: draft ?? this.draft,
        baseline: baseline ?? this.baseline,
        step: step ?? this.step,
        loading: loading ?? this.loading,
        loadFailed: loadFailed ?? this.loadFailed,
        saving: saving ?? this.saving,
        uploading: uploading ?? this.uploading,
        error: clearError ? null : error ?? this.error,
        errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
        eventId: eventId ?? this.eventId,
        status: status ?? this.status,
        problems: problems ?? this.problems,
        policies: policies ?? this.policies,
        countries: countries ?? this.countries,
        states: states ?? this.states,
        cities: cities ?? this.cities,
        countryCode: countryCode ?? this.countryCode,
        stateCode: clearStateCode ? null : stateCode ?? this.stateCode,
        locating: locating ?? this.locating,
        locateProblem:
            clearLocateProblem ? null : locateProblem ?? this.locateProblem,
        ownedVenueIds: ownedVenueIds ?? this.ownedVenueIds,
        affiliations: affiliations ?? this.affiliations,
      );
}

/// Drives the event studio: a new event when [eventId] is null, otherwise the
/// saved event loaded to edit. Its rules follow the web's event builder.
class EventStudioController extends Notifier<EventStudioState> {
  EventStudioController(this.eventId);

  final String? eventId;

  @override
  EventStudioState build() {
    unawaited(Future.microtask(_load));
    return EventStudioState(loading: eventId != null);
  }

  SpacesRepository get _repo => ref.read(spacesRepositoryProvider);

  Future<void> _load() async {
    // Policies, places and venue access are extras: the studio works without
    // them, and a venue the host cannot be shown access for is simply refused.
    unawaited(_loadPolicies());
    unawaited(_loadAccess());
    final countries = _loadCountries();
    final id = eventId;
    if (id == null) return;
    try {
      final detail = await _repo.eventDetail(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        draft: detail.draft,
        baseline: detail.draft.items,
        eventId: detail.id,
        status: detail.status,
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

  Future<void> _loadPolicies() async {
    try {
      final all = await _repo.cancellationPolicies();
      if (!ref.mounted) return;
      state = state.copyWith(policies: all);
    } on Object {
      // Optional.
    }
  }

  /// Which venues the host may use: those they run, and those whose Mayor has
  /// approved (or is still deciding) their application.
  Future<void> _loadAccess() async {
    try {
      final mine = await ref.read(myVenuesProvider.future);
      if (!ref.mounted) return;
      state = state.copyWith(ownedVenueIds: {for (final v in mine) v.id});
    } on Object {
      // Without it only approved affiliations below can be offered.
    }
    try {
      final lists = await ref.read(partnersProvider.future);
      if (!ref.mounted) return;
      final map = <String, VenueAccess>{};
      for (final p in lists.asEventFoxer) {
        if (p.status.name == 'approved') {
          map[p.venueId] = VenueAccess.approved;
        } else if (p.isPending && map[p.venueId] != VenueAccess.approved) {
          map[p.venueId] = VenueAccess.pending;
        }
      }
      state = state.copyWith(affiliations: map);
    } on Object {
      // Optional.
    }
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

  void edit(EventDraft Function(EventDraft draft) change) {
    state = state.copyWith(draft: change(state.draft), clearError: true);
  }

  void goTo(EventStep step) => state = state.copyWith(step: step);

  void next() {
    final i = state.step.index;
    if (i < EventStep.values.length - 1) goTo(EventStep.values[i + 1]);
  }

  void back() {
    final i = state.step.index;
    if (i > 0) goTo(EventStep.values[i - 1]);
  }

  // -- Place ---------------------------------------------------------------

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

  /// Fills in the town and country from where the phone is, as the web's
  /// Use my location does, and keeps the position for the event.
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
    state = state.copyWith(
      draft: state.draft.copyWith(lat: found.lat, lng: found.lng),
    );
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
    }
    if (!ref.mounted) return;
    if (place.city != null) pickCity(place.city!);
    state = state.copyWith(locating: false);
  }

  // -- Photos --------------------------------------------------------------

  /// Uploads a photo and adds it, up to five.
  Future<void> addPhoto(PickedPhoto photo) async {
    if (state.draft.photos.length >= maxEventPhotos) return;
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

  // -- Package -------------------------------------------------------------

  /// Puts something in the package. As on the web, an item already there is
  /// not added twice, only one venue is allowed, and a venue needs the host
  /// to run it or hold an approved affiliation.
  AddResult addItem(PackageItem item) {
    final d = state.draft;
    if (d.items.any((i) => i.id == item.id)) return AddResult.duplicate;

    var toAdd = item;
    if (item.isVenue) {
      final access = state.accessFor(item.id);
      if (access == VenueAccess.pending) return AddResult.venuePending;
      if (access == VenueAccess.none) return AddResult.venueNotApplied;
      if (d.venue != null) return AddResult.alreadyHasVenue;
      toAdd = PackageItem(
        id: item.id,
        name: item.name,
        kind: item.kind,
        cost: item.cost,
        icon: item.icon,
        description: item.description,
        imageUrl: item.imageUrl,
        city: item.city,
        state: item.state,
        country: item.country,
        lat: item.lat,
        lng: item.lng,
      );
    }

    var next = d.copyWith(items: [...d.items, toAdd]);
    // The first venue fills in an empty place, as it does on the web.
    final placeEmpty = d.city.trim().isEmpty && d.state.trim().isEmpty;
    if (toAdd.isVenue && placeEmpty) {
      next = next.copyWith(
        city: toAdd.city,
        state: toAdd.state,
        country: toAdd.country,
        lat: toAdd.lat,
        lng: toAdd.lng,
      );
    }
    state = state.copyWith(draft: next, clearError: true);
    if (toAdd.isVenue && placeEmpty && toAdd.country != null) {
      unawaited(_matchSavedPlace());
    }
    return AddResult.added;
  }

  void removeItem(String id) {
    edit(
      (d) => d.copyWith(
        items: [
          for (final i in d.items)
            if (i.id != id) i,
        ],
      ),
    );
  }

  /// Changes the price agreed for an item, or whether it is optional. A price
  /// of null goes back to the listed one.
  void updateItem(
    String id, {
    double? agreedPrice,
    bool clearPrice = false,
    bool? isOptional,
  }) {
    edit(
      (d) => d.copyWith(
        items: [
          for (final i in d.items)
            if (i.id == id)
              i.copyWith(
                agreedPrice: agreedPrice,
                clearAgreedPrice: clearPrice,
                isOptional: isOptional,
              )
            else
              i,
        ],
      ),
    );
  }

  void setMargin(int pct) => edit((d) => d.copyWith(marginPct: pct));

  // -- Saving --------------------------------------------------------------

  /// Saves the event, and with [submit] sends it for review. It is created
  /// once and updated after, so a retry never makes a second event. Nothing is
  /// submitted if the API refused any package item, so an event never goes for
  /// review without the venue the host chose.
  Future<SaveOutcome> save({required bool submit}) async {
    if (state.saving) return SaveOutcome.blocked;
    final draft = state.draft;
    if (draft.title.trim().isEmpty) {
      state = state.copyWith(error: 'title');
      return SaveOutcome.blocked;
    }
    if (submit && !state.canSubmit) return SaveOutcome.blocked;

    state = state.copyWith(
      saving: true,
      clearError: true,
      problems: const <PackageProblem>[],
    );
    try {
      var id = state.eventId;
      if (id == null) {
        id = await _repo.createEvent(draft);
        if (!ref.mounted) return SaveOutcome.failed;
        state = state.copyWith(eventId: id, status: 'draft');
      } else {
        await _repo.updateEvent(id, draft);
        if (!ref.mounted) return SaveOutcome.failed;
      }

      final problems = await _repo.syncEventPackage(
        id,
        draft.items,
        before: state.baseline,
      );
      if (!ref.mounted) return SaveOutcome.failed;
      // What the API took is now what is saved.
      final refused = {for (final p in problems) p.name};
      state = state.copyWith(
        baseline: [
          for (final i in draft.items)
            if (!refused.contains(i.name)) i,
        ],
        problems: problems,
      );

      if (problems.isNotEmpty) {
        state = state.copyWith(saving: false);
        return SaveOutcome.partial;
      }
      if (submit) {
        await _repo.submitEvent(id);
        if (!ref.mounted) return SaveOutcome.failed;
        state = state.copyWith(saving: false, status: 'pending');
        return SaveOutcome.submitted;
      }
      state = state.copyWith(saving: false);
      return SaveOutcome.saved;
    } on Object catch (e) {
      if (!ref.mounted) return SaveOutcome.failed;
      state = state.copyWith(
        saving: false,
        error: 'save',
        errorDetail: e is AppException ? e.message : null,
      );
      return SaveOutcome.failed;
    }
  }
}

// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final eventStudioProvider = NotifierProvider.autoDispose
    .family<EventStudioController, EventStudioState, String?>(
  EventStudioController.new,
);
