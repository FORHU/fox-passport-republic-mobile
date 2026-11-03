import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/shared/roles/role_request.dart';

class RoleResubmitState {
  const RoleResubmitState({
    this.files = const {},
    this.submitting = false,
    this.error,
  });

  /// The new file chosen for each flagged document, by the name the API
  /// reads it under (`validId1`, `nbiFile`, ...).
  final Map<String, PickedPhoto> files;
  final bool submitting;

  /// What the API said when it refused, or null.
  final String? error;

  RoleResubmitState copyWith({
    Map<String, PickedPhoto>? files,
    bool? submitting,
    String? error,
    bool clearError = false,
  }) =>
      RoleResubmitState(
        files: files ?? this.files,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : error ?? this.error,
      );
}

/// Fixing the documents an admin flagged on an application, and nothing else.
class RoleResubmitController extends Notifier<RoleResubmitState> {
  RoleResubmitController(this.request);

  final RoleRequestSummary request;

  @override
  RoleResubmitState build() => const RoleResubmitState();

  /// Every flagged document has a new file, and there is something to send.
  bool get complete =>
      request.flaggedDocuments.isNotEmpty &&
      request.flaggedDocuments.every(state.files.containsKey);

  void setFile(String field, PickedPhoto photo) {
    state = state.copyWith(
      files: {...state.files, field: photo},
      clearError: true,
    );
  }

  void removeFile(String field) {
    state = state.copyWith(
      files: {...state.files}..remove(field),
      clearError: true,
    );
  }

  /// Sends them. Returns whether the API took them.
  Future<bool> submit() async {
    if (state.submitting || !complete) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await ref
          .read(roleApplicationRepositoryProvider)
          .resubmit(request.id, state.files);
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
final roleResubmitProvider = NotifierProvider.autoDispose
    .family<RoleResubmitController, RoleResubmitState, RoleRequestSummary>(
  RoleResubmitController.new,
);
