import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';

/// Data-layer extension of [UserEntity] that knows how to (de)serialize and
/// carries the auth token returned by the API.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required this.token,
    super.username,
    super.systemRole,
    super.roleType,
    super.isEmailVerified,
    super.imageUrl,
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

    final rawRoles = user['roleType'];
    final roles = rawRoles is List
        ? rawRoles.map((r) => r.toString()).toList()
        : const <String>[];

    return UserModel(
      id: (user['id'] ?? payload['id'] ?? '').toString(),
      email: (user['email'] ?? payload['email'] ?? '').toString(),
      name: (user['name'] ?? user['username'] ?? payload['name'] ?? '')
          .toString(),
      token: token,
      username: (user['username'] ?? '').toString(),
      systemRole: (user['systemRole'] ?? 'user').toString(),
      roleType: roles,
      // The API's login payload omits this flag, but it refuses to sign in an
      // unverified account — so a user we received at all is verified.
      isEmailVerified: user['isEmailVerified'] != false,
      imageUrl: _photo(user),
    );
  }

  /// The profile photo, from whichever field the response carries it in.
  static String? _photo(Map<String, dynamic> user) {
    for (final key in const ['imgId', 'image', 'profileImage']) {
      final value = user[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// The Better Auth session token, sent as a bearer token.
  final String token;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'username': username,
        'systemRole': systemRole,
        'roleType': roleType,
        'isEmailVerified': isEmailVerified,
        'imgId': imageUrl,
        'token': token,
      };

  @override
  List<Object?> get props => [...super.props, token];
}
