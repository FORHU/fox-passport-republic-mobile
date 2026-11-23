import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/domain/provider_application.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/roles/role_request.dart';

/// The wizard's screens, in order (mobile#487).
enum ProviderApplyStep {
  intro,
  business,
  categories,
  details,
  documents,
  review,
  sent,
}

class ProviderApplicationState {
  const ProviderApplicationState({
    this.draft = const ProviderApplicationDraft(),
    this.step = ProviderApplyStep.intro,
    this.openDetail,
    this.submitting = false,
    this.error,
    this.sentAt,
    this.locating = false,
    this.locateProblem,
    this.locatedCount = 0,
  });

  final ProviderApplicationDraft draft;
  final ProviderApplyStep step;

  /// Finding the phone's location for "Where you're based".
  final bool locating;

  /// Why the last try found nothing, or null.
  final LocateOutcome? locateProblem;

  /// Goes up each time the location fills "Where you're based", so the field
  /// shows the new text.
  final int locatedCount;

  /// The category open for editing on the details step.
  final String? openDetail;
  final bool submitting;

  /// What the API said when it refused, or '' for an unknown failure.
  final String? error;
  final DateTime? sentAt;

  ProviderApplicationState copyWith({
    ProviderApplicationDraft? draft,
    ProviderApplyStep? step,
    String? openDetail,
    bool? submitting,
    String? error,
    bool clearError = false,
    DateTime? sentAt,
    bool? locating,
    LocateOutcome? locateProblem,
    bool clearLocateProblem = false,
    int? locatedCount,
  }) =>
      ProviderApplicationState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        openDetail: openDetail ?? this.openDetail,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : error ?? this.error,
        sentAt: sentAt ?? this.sentAt,
        locating: locating ?? this.locating,
        locateProblem:
            clearLocateProblem ? null : locateProblem ?? this.locateProblem,
        locatedCount: locatedCount ?? this.locatedCount,
      );
}

/// Holds a Provider application across the wizard's screens. It is kept while
/// the app runs, so leaving and coming back keeps the answers.
class ProviderApplicationController extends Notifier<ProviderApplicationState> {
  @override
  ProviderApplicationState build() {
    // Signing out or switching account starts afresh: the draft holds ID
    // photos and must never carry over to the next person on this phone.
    ref.watch(currentUserIdProvider);
    return const ProviderApplicationState();
  }

  void edit(ProviderApplicationDraft Function(ProviderApplicationDraft) f) {
    state = state.copyWith(draft: f(state.draft), clearError: true);
  }

  /// Typing a place drops the located position: it may no longer match.
  void setBasedIn(String text) {
    edit((d) => d.copyWith(basedIn: text, clearBasedInPoint: true));
  }

  /// Fills "Where you're based" with the phone's city and province, and keeps
  /// the position for finding Providers near a venue.
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
    final point = (lat: found.lat!, lng: found.lng!);
    final place = await locator.placeAt(point.lat, point.lng);
    if (!ref.mounted) return;
    final name =
        [place.city, place.province].whereType<String>().toSet().join(', ');
    if (name.isEmpty) {
      state = state.copyWith(
        locating: false,
        locateProblem: LocateOutcome.failed,
      );
      return;
    }
    state = state.copyWith(
      draft: state.draft.copyWith(basedIn: name, basedInPoint: point),
      locating: false,
      locatedCount: state.locatedCount + 1,
      clearError: true,
    );
  }

  void goTo(ProviderApplyStep step) {
    if (step == ProviderApplyStep.details) {
      state = state.copyWith(step: step, openDetail: _firstUnfinished());
    } else {
      state = state.copyWith(step: step);
    }
  }

  void next() {
    final i = state.step.index;
    if (i < ProviderApplyStep.review.index) {
      goTo(ProviderApplyStep.values[i + 1]);
    }
  }

  /// Steps back. Returns false on the first screen and after sending, where
  /// leaving the page is the way back.
  bool back() {
    final step = state.step;
    if (step == ProviderApplyStep.intro || step == ProviderApplyStep.sent) {
      return false;
    }
    goTo(ProviderApplyStep.values[step.index - 1]);
    return true;
  }

  String? _firstUnfinished() {
    final d = state.draft;
    for (final s in d.orderedSpecializations) {
      if (!d.detailFor(s).isDone) return s;
    }
    return d.orderedSpecializations.isEmpty
        ? null
        : d.orderedSpecializations.first;
  }

  /// Picks or drops a category. The first one picked is the main one until
  /// another is starred; dropping the main one passes it to the next.
  void toggle(String slug) {
    final d = state.draft;
    if (d.specializations.contains(slug)) {
      final rest = [...d.specializations]..remove(slug);
      final main = d.mainSpecialty == slug
          ? (rest.isEmpty ? null : rest.first)
          : d.mainSpecialty;
      edit(
        (x) => x.copyWith(
          specializations: rest,
          mainSpecialty: main,
          clearMain: main == null,
        ),
      );
    } else {
      edit(
        (x) => x.copyWith(
          specializations: [...d.specializations, slug],
          mainSpecialty: d.mainSpecialty ?? slug,
        ),
      );
    }
  }

  void makeMain(String slug) {
    if (!state.draft.specializations.contains(slug)) return;
    edit((x) => x.copyWith(mainSpecialty: slug));
  }

  void openDetail(String slug) => state = state.copyWith(openDetail: slug);

  void _setDetail(
    String slug,
    ProviderSpecialtyDetail Function(ProviderSpecialtyDetail) f,
  ) {
    final d = state.draft;
    edit(
      (x) => x.copyWith(details: {...d.details, slug: f(d.detailFor(slug))}),
    );
  }

  void setDescription(String slug, String text) =>
      _setDetail(slug, (x) => x.copyWith(description: text));

  void addPhoto(String slug, PickedPhoto photo) => _setDetail(slug, (x) {
        if (x.photos.length >= ProviderApplicationDraft.maxPhotos) return x;
        return x.copyWith(photos: [...x.photos, photo]);
      });

  void removePhoto(String slug, int index) => _setDetail(
        slug,
        (x) => x.copyWith(photos: [...x.photos]..removeAt(index)),
      );

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
      await ref.read(roleApplicationRepositoryProvider).submitProvider(
            state.draft,
          );
      ref.invalidate(myRoleRequestsProvider);
      if (!ref.mounted) return true;
      state = state.copyWith(
        submitting: false,
        step: ProviderApplyStep.sent,
        sentAt: DateTime.now(),
      );
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

  /// Clears the application once it was sent, for a later one.
  void reset() => state = const ProviderApplicationState();
}

final NotifierProvider<ProviderApplicationController, ProviderApplicationState>
    providerApplicationProvider =
    NotifierProvider<ProviderApplicationController, ProviderApplicationState>(
  ProviderApplicationController.new,
);
