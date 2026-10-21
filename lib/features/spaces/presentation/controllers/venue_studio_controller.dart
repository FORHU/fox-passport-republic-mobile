import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';

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
    // The map and the policy list are extras: the studio works without them.
    unawaited(_loadNeighbours());
    unawaited(_loadPolicies());
    final id = venueId;
    if (id == null) return;
    try {
      final detail = await _repo.venueDetail(id);
      state = state.copyWith(
        draft: detail.draft,
        live: detail.isLive,
        loading: false,
      );
    } on Object {
      state = state.copyWith(loading: false, loadFailed: true);
    }
  }

  Future<void> _loadNeighbours() async {
    try {
      final all = await _repo.neighbourBoundaries(excludeId: venueId);
      state = state.copyWith(neighbours: all);
    } on Object {
      // The API still refuses an overlap when the host saves.
    }
  }

  Future<void> _loadPolicies() async {
    try {
      final all = await _repo.cancellationPolicies();
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
      state = state.copyWith(
        uploading: false,
        draft: state.draft.copyWith(
          photos: [...state.draft.photos, uploaded],
        ),
      );
    } on Object {
      state = state.copyWith(uploading: false, error: 'photo');
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
      state = state.copyWith(saving: false);
      return true;
    } on Object catch (e) {
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
