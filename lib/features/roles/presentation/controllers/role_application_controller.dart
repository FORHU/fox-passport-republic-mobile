import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/roles/role_request.dart';

class RoleApplicationState {
  const RoleApplicationState({
    required this.draft,
    this.submitting = false,
    this.error,
  });

  final RoleApplicationDraft draft;
  final bool submitting;

  /// What the API said when it refused, or null.
  final String? error;

  RoleApplicationState copyWith({
    RoleApplicationDraft? draft,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) =>
      RoleApplicationState(
        draft: draft ?? this.draft,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : error ?? this.error,
      );
}

class RoleApplicationController extends Notifier<RoleApplicationState> {
  RoleApplicationController(this.roleType);

  final String roleType;

  @override
  RoleApplicationState build() => RoleApplicationState(
        draft: RoleApplicationDraft(roleType: roleType),
      );

  void edit(RoleApplicationDraft Function(RoleApplicationDraft) change) {
    state = state.copyWith(draft: change(state.draft), clearError: true);
  }

  /// Picks or drops a specialization, keeping to three.
  void toggleSpecialization(String value) {
    final now = state.draft.specializations;
    if (now.contains(value)) {
      edit((d) => d.copyWith(specializations: [...now]..remove(value)));
    } else if (now.length < RoleApplicationDraft.maxSpecializations) {
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
