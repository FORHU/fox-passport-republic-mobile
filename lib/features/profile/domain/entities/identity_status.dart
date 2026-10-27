/// The documents the API accepts as proof of identity.
enum IdType {
  passport('passport'),
  driversLicense('drivers_license'),
  nationalId('national_id'),
  other('other');

  const IdType(this.wire);

  /// What the API calls it.
  final String wire;
}

/// One ID submission and what became of it.
class IdentitySubmission {
  const IdentitySubmission({
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  factory IdentitySubmission.fromJson(Map<String, dynamic> json) {
    final reason = (json['rejectionReason'] as String?)?.trim();
    return IdentitySubmission(
      status: '${json['status']}',
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal(),
      rejectionReason: reason == null || reason.isEmpty ? null : reason,
    );
  }

  /// `pending`, `approved` or `rejected`.
  final String status;
  final DateTime? createdAt;
  final String? rejectionReason;
}

/// Whether you carry the Verified badge, and your latest submission.
class IdentityStatus {
  const IdentityStatus({this.verifiedAt, this.latest});

  factory IdentityStatus.fromJson(Object? json) {
    if (json is! Map) return const IdentityStatus();
    final latest = json['latest'];
    return IdentityStatus(
      verifiedAt: DateTime.tryParse('${json['verifiedAt']}')?.toLocal(),
      latest: latest is Map
          ? IdentitySubmission.fromJson(latest.cast<String, dynamic>())
          : null,
    );
  }

  final DateTime? verifiedAt;
  final IdentitySubmission? latest;

  bool get isVerified => verifiedAt != null;
  bool get isPending => !isVerified && latest?.status == 'pending';

  /// A new submission is possible: not verified and none waiting.
  bool get canSubmit => !isVerified && !isPending;
}
