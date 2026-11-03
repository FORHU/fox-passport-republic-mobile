import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';

/// Sends an application for a role. The API keeps the documents private.
class RoleApplicationRepository {
  RoleApplicationRepository(this._api);

  final ApiService _api;

  Future<void> submit(RoleApplicationDraft draft) async {
    await _api.post(ApiEndpoints.roleRequestsApply, draft.toForm());
  }
}

final roleApplicationRepositoryProvider = Provider<RoleApplicationRepository>(
  (ref) => RoleApplicationRepository(ref.watch(apiServiceProvider)),
);
