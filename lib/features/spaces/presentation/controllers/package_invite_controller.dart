import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/spaces/data/package_invites_repository.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';

class PackageInviteState {
  const PackageInviteState({this.sending = false, this.error});

  final bool sending;

  /// What the API said when it refused, or '' for an unknown failure.
  final String? error;
}

/// Answers one package invite (api#447): join, or decline with a reason.
class PackageInviteController extends Notifier<PackageInviteState> {
  @override
  PackageInviteState build() => const PackageInviteState();

  /// Sends the answer. Returns whether the API took it.
  Future<bool> respond(
    PackageInvite invite, {
    required bool accept,
    InviteDeclineReason? reason,
    String? note,
  }) async {
    if (state.sending) return false;
    if (!accept && reason == null) return false;
    if (reason == InviteDeclineReason.other && (note ?? '').trim().isEmpty) {
      return false;
    }
    state = const PackageInviteState(sending: true);
    try {
      await ref.read(packageInvitesRepositoryProvider).respond(
            invite,
            accept: accept,
            reason: reason,
            note: note,
          );
      ref.invalidate(packageInvitesProvider);
      if (!ref.mounted) return true;
      state = const PackageInviteState();
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = PackageInviteState(error: e is AppException ? e.message : '');
      return false;
    }
  }
}

final NotifierProvider<PackageInviteController, PackageInviteState>
    packageInviteControllerProvider =
    NotifierProvider.autoDispose<PackageInviteController, PackageInviteState>(
  PackageInviteController.new,
);
