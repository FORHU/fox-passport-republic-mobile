import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';

/// Data-layer extension of [ProfileEntity] that knows how to deserialize.
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.username,
    super.phone,
    super.imageUrl,
    super.isPrivate,
    super.bio,
    super.joinedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map)
            ? (json['data'] as Map).cast<String, dynamic>()
            : json;

    String? text(String key) {
      final v = payload[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return ProfileModel(
      id: (payload['id'] ?? '').toString(),
      name: (payload['name'] ?? payload['username'] ?? '').toString(),
      email: (payload['email'] ?? '').toString(),
      username: text('username') ?? '',
      phone: text('phone'),
      imageUrl: text('imgId'),
      isPrivate: payload['isPrivate'] == true,
      bio: payload['bio'] as String?,
      joinedAt: (payload['createdAt'] ?? payload['joinedAt']) != null
          ? DateTime.tryParse(
              (payload['createdAt'] ?? payload['joinedAt']).toString(),
            )
          : null,
    );
  }
}
