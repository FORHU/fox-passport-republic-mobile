import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';

/// Data-layer extension of [UserEntity] that knows how to (de)serialize and
/// carries the auth token returned by the API.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required this.token,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map)
            ? (json['data'] as Map).cast<String, dynamic>()
            : json;
    final user = (payload['user'] is Map<String, dynamic>)
        ? payload['user'] as Map<String, dynamic>
        : (payload['user'] is Map)
            ? (payload['user'] as Map).cast<String, dynamic>()
            : payload;

    final token = (payload['token'] ?? payload['accessToken'] ?? '').toString();
    final refreshToken = payload['refreshToken'] as String?;

    return UserModel(
      id: (user['id'] ?? payload['id'] ?? '').toString(),
      email: (user['email'] ?? payload['email'] ?? '').toString(),
      name: (user['name'] ??
              user['username'] ??
              payload['name'] ??
              '')
          .toString(),
      token: token,
      refreshToken: refreshToken,
    );
  }

  /// Short-lived access token (bearer).
  final String token;

  /// Long-lived token used to obtain a new access token. Optional — some
  /// backends issue only an access token.
  final String? refreshToken;

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'token': token,
    'refreshToken': refreshToken,
  };

  @override
  List<Object?> get props => [...super.props, token, refreshToken];
}
