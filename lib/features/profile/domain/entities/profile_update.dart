import 'package:equatable/equatable.dart';

/// What to change on the profile: only the fields that are set are sent, as
/// `PUT /profile` takes them.
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.name,
    this.username,
    this.phone,
    this.imageUrl,
    this.isPrivate,
    this.bio,
    this.socialLinks,
  });

  final String? name;
  final String? username;
  final String? phone;

  /// The URL of an uploaded photo (the API's `profileImage`).
  final String? imageUrl;
  final bool? isPrivate;

  /// A few lines about them. An empty one clears it.
  final String? bio;

  /// Every link they want shown, by the API's platform name. These replace the
  /// ones stored, so an empty map clears them all.
  final Map<String, String>? socialLinks;

  /// The request body.
  Map<String, Object> toJson() => {
        if (name != null) 'name': name!,
        if (username != null) 'username': username!,
        if (phone != null) 'phone': phone!,
        if (imageUrl != null) 'profileImage': imageUrl!,
        if (isPrivate != null) 'isPrivate': isPrivate!,
        if (bio != null) 'bio': bio!,
        if (socialLinks != null) 'socialLinks': socialLinks!,
      };

  @override
  List<Object?> get props =>
      [name, username, phone, imageUrl, isPrivate, bio, socialLinks];
}
