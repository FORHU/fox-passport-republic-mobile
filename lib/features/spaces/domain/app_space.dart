import 'package:flutter/material.dart';

/// Where in the app a person is working. Everyone has the Citizen space; the
/// others open up with a role they hold (an account can hold several).
enum AppSpace {
  citizen(root: '/', icon: Icons.explore_outlined),
  venue(
    root: '/space/venue',
    icon: Icons.storefront_outlined,
    requiredRoles: ['venueFoxer'],
  ),
  event(
    root: '/space/event',
    icon: Icons.celebration_outlined,
    requiredRoles: ['eventFoxer'],
  ),
  // Gear owns assets; Service and Performer Foxers both list services (the web
  // gives them the same list under two permissions), so a Performer opens the
  // Services space.
  gear(
    root: '/space/gear',
    icon: Icons.inventory_2_outlined,
    requiredRoles: ['gearFoxer'],
  ),
  services(
    root: '/space/services',
    icon: Icons.design_services_outlined,
    requiredRoles: ['serviceFoxer', 'performerFoxer'],
  );

  const AppSpace({
    required this.root,
    required this.icon,
    this.requiredRoles = const [],
  });

  /// Where the space opens.
  final String root;
  final IconData icon;

  /// The `RoleType`s that open this space: holding any one is enough. Empty
  /// for Citizen, which everyone has.
  final List<String> requiredRoles;

  bool isAvailableTo(List<String> roles) =>
      requiredRoles.isEmpty || requiredRoles.any(roles.contains);

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
