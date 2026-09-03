import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';

/// Data-layer extension of [ProfileEntity] that knows how to deserialize.
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.bio,
    super.joinedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    bio: json['bio'] as String?,
    joinedAt: json['joinedAt'] != null
        ? DateTime.tryParse(json['joinedAt'] as String)
        : null,
  );
}
