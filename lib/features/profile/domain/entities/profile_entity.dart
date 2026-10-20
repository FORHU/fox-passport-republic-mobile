import 'package:equatable/equatable.dart';

/// Extended profile info beyond the auth session's user record: fetched
/// separately from `GET /profile`, since not every backend returns bio, phone
/// or join-date on login.
class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.phone,
    this.imageUrl,
    this.isPrivate = false,
    this.bio,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String? phone;

  /// The profile photo (the API's `imgId`), or null when there is none.
  final String? imageUrl;

  /// A private profile: other people cannot send a follow request freely.
  final bool isPrivate;
  final String? bio;
  final DateTime? joinedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        username,
        phone,
        imageUrl,
        isPrivate,
        bio,
        joinedAt,
      ];
}
