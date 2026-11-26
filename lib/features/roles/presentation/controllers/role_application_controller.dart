import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/domain/tax_id.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/roles/role_request.dart';

class RoleApplicationState {
  const RoleApplicationState({
    required this.draft,
    this.submitting = false,
    this.error,
    this.locating = false,
    this.locateProblem,
    this.locatedCount = 0,
    this.taxCountries = const [],
    this.tinFormats,
  });

  final RoleApplicationDraft draft;
  final bool submitting;

  /// What the API said when it refused, or null.
  final String? error;

  /// Finding the phone's location for the city and province.
  final bool locating;

  /// Why the last try found nothing, or null.
  final LocateOutcome? locateProblem;

  /// Goes up each time the location fills the fields, so they show it.
  final int locatedCount;

  /// Venue only: the countries the tax number can be from (mobile#529).
  /// Empty until loaded, or when they could not be.
  final List<TaxCountry> taxCountries;

  /// How the chosen tax country's numbers look, or null when not known yet
  /// (the API still checks the number when it is sent).
  final TinFormats? tinFormats;

  /// Whether the tax number fits the chosen country's formats, as far as the
  /// app knows them.
  bool get tinFits {
    final value = draft.tinNumber.trim();
    if (value.isEmpty) return false;
    return tinFormats?.accepts(value) ?? true;
  }

  RoleApplicationState copyWith({
    RoleApplicationDraft? draft,
    bool? submitting,
    String? error,
    bool clearError = false,
    bool? locating,
    LocateOutcome? locateProblem,
    bool clearLocateProblem = false,
    int? locatedCount,
    List<TaxCountry>? taxCountries,
    TinFormats? tinFormats,
    bool clearTinFormats = false,
  }) =>
      RoleApplicationState(
        draft: draft ?? this.draft,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : error ?? this.error,
        locating: locating ?? this.locating,
        locateProblem:
            clearLocateProblem ? null : locateProblem ?? this.locateProblem,
        locatedCount: locatedCount ?? this.locatedCount,
        taxCountries: taxCountries ?? this.taxCountries,
        tinFormats: clearTinFormats ? null : tinFormats ?? this.tinFormats,
      );
}

class RoleApplicationController extends Notifier<RoleApplicationState> {
  RoleApplicationController(this.roleType);

  final String roleType;

  @override
  RoleApplicationState build() {
    if (roleType == 'venueFoxer') unawaited(Future.microtask(_loadTaxCountry));
    return RoleApplicationState(
      draft: RoleApplicationDraft(roleType: roleType),
    );
  }

  void edit(RoleApplicationDraft Function(RoleApplicationDraft) change) {
    state = state.copyWith(draft: change(state.draft), clearError: true);
  }

  /// Starts the tax country on the person's own country, else the
  /// Philippines, and loads the countries to choose from (mobile#529).
  Future<void> _loadTaxCountry() async {
    final repo = ref.read(roleApplicationRepositoryProvider);
    var countries = const <TaxCountry>[];
    var profileCountry = '';
    try {
      countries = await repo.taxCountries();
    } on Object {
      // The field still works on the Philippines; the API checks the number.
    }
    try {
      profileCountry = await repo.profileCountry();
    } on Object {
      // No profile country: start on the Philippines.
    }
    if (!ref.mounted) return;
    // The list and the chosen country arrive together, so the country
    // dropdown, which reads its value once, never starts empty.
    final code = state.draft.tinCountry.isEmpty
        ? taxCountryFor(profileCountry, countries)
        : state.draft.tinCountry;
    state = state.copyWith(
      taxCountries: countries,
      draft: state.draft.copyWith(
        tinCountry: code,
        phoneCode: _phoneCodeOf(code, countries),
      ),
    );
    await _loadTinFormats(code);
  }

  /// Chooses the application's country. The tax number and the contact
  /// number both follow it (mobile#529, #537); this loads its tax formats.
  Future<void> setTinCountry(String code) async {
    state = state.copyWith(
      draft: state.draft.copyWith(
        tinCountry: code,
        phoneCode: _phoneCodeOf(code, state.taxCountries),
      ),
      clearTinFormats: true,
      clearError: true,
    );
    await _loadTinFormats(code);
  }

  /// [code]'s calling code, or '' when the list doesn't have it. A number
  /// sent without a code is read as Philippine, as before.
  static String _phoneCodeOf(String code, List<TaxCountry> countries) {
    for (final c in countries) {
      if (c.code == code) return c.phoneCode;
    }
    return '';
  }

  Future<void> _loadTinFormats(String code) async {
    TinFormats? formats;
    try {
      formats = await ref.read(roleApplicationRepositoryProvider).tinFormats(
            code,
          );
    } on Object {
      formats = null;
    }
    if (!ref.mounted || state.draft.tinCountry != code) return;
    state = state.copyWith(
      tinFormats: formats,
      clearTinFormats: formats == null,
      draft: state.draft.copyWith(taxIdIssued: formats?.issuesTin ?? true),
    );
  }

  /// Fills the city and province from the phone's location (Event Foxer and
  /// Event Coordinator). What was typed stays when nothing is found.
  Future<void> useMyLocation() async {
    if (state.locating) return;
    state = state.copyWith(locating: true, clearLocateProblem: true);
    final locator = ref.read(deviceLocatorProvider);
    final found = await locator.locate();
    if (!ref.mounted) return;
    if (!found.isOk) {
      state = state.copyWith(
        locating: false,
        locateProblem: found.outcome == LocateOutcome.ok
            ? LocateOutcome.failed
            : found.outcome,
      );
      return;
    }
    final place = await locator.placeAt(found.lat!, found.lng!);
    if (!ref.mounted) return;
    final city = place.city;
    if (city == null) {
      state = state.copyWith(
        locating: false,
        locateProblem: LocateOutcome.failed,
      );
      return;
    }
    state = state.copyWith(
      draft: state.draft.copyWith(city: city, state: place.province),
      locating: false,
      locatedCount: state.locatedCount + 1,
      clearError: true,
    );
  }

  /// Picks or drops a specialization. A Provider may pick any number; the
  /// other roles keep to three.
  void toggleSpecialization(String value) {
    final now = state.draft.specializations;
    final max = RoleApplicationDraft.maxSpecializationsFor(roleType);
    if (now.contains(value)) {
      edit((d) => d.copyWith(specializations: [...now]..remove(value)));
    } else if (max == null || now.length < max) {
      edit((d) => d.copyWith(specializations: [...now, value]));
    }
  }

  void setDocument(KycDocument slot, PickedPhoto photo) {
    edit((d) => d.copyWith(documents: {...d.documents, slot: photo}));
  }

  void removeDocument(KycDocument slot) {
    edit((d) => d.copyWith(documents: {...d.documents}..remove(slot)));
  }

  /// Sends it. Returns whether the API took it.
  Future<bool> submit() async {
    if (state.submitting || !state.draft.isComplete) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await ref.read(roleApplicationRepositoryProvider).submit(state.draft);
      ref.invalidate(myRoleRequestsProvider);
      if (!ref.mounted) return true;
      state = state.copyWith(submitting: false);
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        submitting: false,
        error: e is AppException ? e.message : '',
      );
      return false;
    }
  }
}

// The family type is not exported by flutter_riverpod, so it is inferred.
// ignore: specify_nonobvious_property_types
final roleApplicationProvider = NotifierProvider.autoDispose
    .family<RoleApplicationController, RoleApplicationState, String>(
  RoleApplicationController.new,
);
