import 'package:flutter/material.dart';

/// Where in the app a person is working. Everyone has the Citizen space; the
/// others open up with a role they hold (an account can hold several).
enum AppSpace {
  citizen(root: '/', icon: Icons.explore_outlined),
  venue(
    root: '/space/venue',
    icon: Icons.storefront_outlined,
    requiredRole: 'venueFoxer',
  ),
  event(
    root: '/space/event',
    icon: Icons.celebration_outlined,
    requiredRole: 'eventFoxer',
  );

  const AppSpace({required this.root, required this.icon, this.requiredRole});

  /// Where the space opens.
  final String root;
  final IconData icon;

  /// The `RoleType` that opens this space; null for Citizen.
  final String? requiredRole;

  bool isAvailableTo(List<String> roles) =>
      requiredRole == null || roles.contains(requiredRole);

  /// The spaces a person with [roles] can switch between, Citizen first.
  static List<AppSpace> availableTo(List<String> roles) => [
        for (final space in values)
          if (space.isAvailableTo(roles)) space,
      ];

  /// The space a location belongs to, or null for the Citizen app.
  static AppSpace? forPath(String path) {
    for (final space in values) {
      if (space == citizen) continue;
      if (path == space.root || path.startsWith('${space.root}/')) {
        return space;
      }
    }
    return null;
  }

  /// A saved name back to a space; Citizen when it is missing or unknown.
  static AppSpace fromName(String? name) => values.firstWhere(
        (space) => space.name == name,
        orElse: () => citizen,
      );
}
