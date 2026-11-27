import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/shared/roles/role_request.dart';

/// Withdrawing a role application still under review (api#367). The state is
/// the id of the application being withdrawn, or null.
class RoleWithdrawController extends Notifier<String?> {
  @override
  String? build() => null;

  /// Takes it back. Returns null when the API took it, or what it said when
  /// it refused ('' when there is nothing to show; the page uses its own
  /// sentence then).
  Future<String?> withdraw(String requestId) async {
    if (state != null) return '';
    state = requestId;
    try {
      await ref.read(roleApplicationRepositoryProvider).withdraw(requestId);
      return null;
    } on Object catch (e) {
      return e is AppException ? e.message : '';
    } finally {
      // Either way, show where the applications stand now. The page may
      // have closed meanwhile, which disposed this controller.
      if (ref.mounted) {
        ref.invalidate(myRoleRequestsProvider);
        state = null;
      }
    }
  }
}

final NotifierProvider<RoleWithdrawController, String?> roleWithdrawProvider =
    NotifierProvider.autoDispose<RoleWithdrawController, String?>(
  RoleWithdrawController.new,
);
