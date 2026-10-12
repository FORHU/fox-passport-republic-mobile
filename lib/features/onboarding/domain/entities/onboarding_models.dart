import 'package:equatable/equatable.dart';

class GeoCountry extends Equatable {
  const GeoCountry({required this.code, required this.name});

  factory GeoCountry.fromJson(Map<String, dynamic> json) => GeoCountry(
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

class GeoState extends Equatable {
  const GeoState({required this.code, required this.name});

  factory GeoState.fromJson(Map<String, dynamic> json) => GeoState(
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

/// One of the user's role applications (`GET /role-requests/my`).
class RoleRequestSummary extends Equatable {
  const RoleRequestSummary({
    required this.id,
    required this.roleType,
    required this.status,
  });

  factory RoleRequestSummary.fromJson(Map<String, dynamic> json) =>
      RoleRequestSummary(
        id: (json['id'] ?? '').toString(),
        roleType: (json['roleType'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
      );

  final String id;
  final String roleType;

  /// `pending`, `revision_requested`, `approved`, `rejected`, …
  final String status;

  bool get isPending => status == 'pending';
  bool get needsRevision => status == 'revision_requested';

  @override
  List<Object?> get props => [id, roleType, status];
}

/// What the profile step is pre-filled with, from `GET /profile`.
class ProfileSeed extends Equatable {
  const ProfileSeed({
    this.name = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.district = '',
  });

  factory ProfileSeed.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? (json['data'] as Map).cast<String, dynamic>()
        : json;
    String read(String key) => (data[key] ?? '').toString();
    return ProfileSeed(
      name: read('name'),
      country: read('country'),
      state: read('state'),
      city: read('city'),
      district: read('district'),
    );
  }

  final String name;
  final String country;
  final String state;
  final String city;
  final String district;

  @override
  List<Object?> get props => [name, country, state, city, district];
}
