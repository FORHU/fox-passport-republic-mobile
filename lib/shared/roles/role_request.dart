import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// One of the user's role applications (`GET /role-requests/my`).
class RoleRequestSummary extends Equatable {
  const RoleRequestSummary({
    required this.id,
    required this.roleType,
    required this.status,
    this.flaggedDocuments = const [],
    this.revisionNote,
  });

  factory RoleRequestSummary.fromJson(Map<String, dynamic> json) =>
      RoleRequestSummary(
        id: (json['id'] ?? '').toString(),
        roleType: (json['roleType'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        flaggedDocuments: [
          if (json['flaggedDocuments'] case final List<Object?> flagged)
            for (final field in flagged)
              if (field != null) field.toString(),
        ],
        revisionNote: json['revisionNote']?.toString(),
      );

  final String id;
  final String roleType;

  /// `pending`, `revision_requested`, `approved`, `rejected`, …
  final String status;

  /// When an admin asked for changes: the documents to replace, by the name
  /// the API gives them (`validId1`, `nbiFile`, ...), and why.
  final List<String> flaggedDocuments;
  final String? revisionNote;

  bool get isPending => status == 'pending';
  bool get needsRevision => status == 'revision_requested';
  bool get isApproved => status == 'approved';

  @override
  List<Object?> get props =>
      [id, roleType, status, flaggedDocuments, revisionNote];
}

/// The user's role applications, newest first as the API returns them.
final FutureProvider<List<RoleRequestSummary>> myRoleRequestsProvider =
    FutureProvider.autoDispose<List<RoleRequestSummary>>((ref) async {
  final body =
      await ref.watch(apiServiceProvider).get(ApiEndpoints.roleRequestsMine);
  final data = body is Map ? body['data'] : null;
  if (data is! List) return const [];
  return [
    for (final row in data)
      if (row is Map) RoleRequestSummary.fromJson(row.cast<String, dynamic>()),
  ];
});
