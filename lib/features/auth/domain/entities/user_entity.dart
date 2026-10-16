import 'package:equatable/equatable.dart';

/// Pure domain object — no JSON, no framework types. Equatable gives value
/// equality so two users with the same fields compare equal.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.username = '',
    this.systemRole = 'user',
    this.roleType = const [],
    this.isEmailVerified = false,
    this.imageUrl,
  });

  final String id;
  final String email;
  final String name;
  final String username;

  /// `user` | `admin_secretary` | `admin` — mirrors the API's `SystemRole`.
  final String systemRole;

  /// Supply-side capabilities (`venueFoxer`, `eventFoxer`, `gearFoxer`,
  /// `serviceFoxer`, `performerFoxer`, `investor`, `organizer`). Empty for a
  /// plain Citizen — see CONTEXT.md in the web repo.
  final List<String> roleType;
  final bool isEmailVerified;

  /// Profile photo (the API's `imgId`), or null when they have none.
  final String? imageUrl;

  /// A Citizen holds no RoleType.
  bool get isCitizen => roleType.isEmpty;
  bool get isAdmin => systemRole == 'admin' || systemRole == 'admin_secretary';
  bool hasRole(String role) => roleType.contains(role);

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        username,
        systemRole,
        roleType,
        isEmailVerified,
        imageUrl,
      ];
}
