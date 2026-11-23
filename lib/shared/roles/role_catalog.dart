// ignore_for_file: no_adjacent_strings_in_list -
// long catalogue copy ported verbatim from the web app.

import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// A dedicated subsection under Provider Foxer (Equipment, Services,
/// Performers, or Event Coordinator).
class RoleCatalogSubsection {
  const RoleCatalogSubsection({
    required this.key,
    required this.roleType,
    required this.title,
    required this.desc,
    required this.href,
  });

  final String key;
  final String roleType;
  final String title;
  final String desc;
  final String href;
}

/// A role a Citizen can apply for from onboarding. Port of the web app's
/// `features/onboarding/roleCatalog.ts` — keep the copy in step with it.
class RoleCatalogEntry {
  const RoleCatalogEntry({
    required this.type,
    required this.roleType,
    required this.href,
    required this.color,
    required this.icon,
    required this.title,
    required this.desc,
    required this.responsibilities,
    required this.requirements,
    this.subsections = const [],
  });

  final String type;

  /// The API's `RoleType` enum value (also what `User.roleType` holds).
  final String roleType;

  /// Path of the application form on the web app.
  final String href;
  final Color color;
  final IconData icon;
  final String title;
  final String desc;

  /// Subsections under Provider Foxer.
  final List<RoleCatalogSubsection> subsections;

  /// What someone holding this role does day to day.
  final List<String> responsibilities;

  /// What the application form will ask for.
  final List<String> requirements;
}

const providerSubsections = <RoleCatalogSubsection>[
  RoleCatalogSubsection(
    key: 'gear',
    roleType: 'providerFoxer',
    title: 'Equipment & Gear',
    desc: 'Rent out sound systems, lighting, furniture, staging, and decor.',
    href: '/foxer/apply?type=provider',
  ),
  RoleCatalogSubsection(
    key: 'services',
    roleType: 'providerFoxer',
    title: 'Talent & Services',
    desc: 'Provide catering, event design, photography, videography, or staff.',
    href: '/foxer/apply?type=provider',
  ),
  RoleCatalogSubsection(
    key: 'performers',
    roleType: 'providerFoxer',
    title: 'Live Entertainment',
    desc: 'Perform live as a DJ, band, MC, or stage act for events.',
    href: '/foxer/apply?type=provider',
  ),
  RoleCatalogSubsection(
    key: 'coordinator',
    roleType: 'organizer',
    title: 'Event Coordinator',
    desc: 'Execute event logistics and manage on-site operations.',
    href: '/foxer/apply?type=organizer',
  ),
];

/// Display title for any `roleType`, including sub-roles not listed as
/// top-level cards in [roleCatalog].
String? roleTitleFor(String roleType) {
  for (final r in roleCatalog) {
    if (r.roleType == roleType) return r.title;
  }
  return switch (roleType) {
    'organizer' => 'Event Coordinator',
    'investor' => 'Partner Foxer',
    _ => null,
  };
}

const _businessDocuments =
    'Valid ID, police clearance (PDF), tax ID, business permit, and a '
    'verification selfie';

const roleCatalog = <RoleCatalogEntry>[
  RoleCatalogEntry(
    type: 'provider',
    roleType: 'providerFoxer',
    href: '/foxer/apply?type=provider',
    color: AppColors.roleProvider,
    icon: Icons.build_rounded,
    title: 'Provider Foxer',
    desc: 'Supply equipment, talent services, live entertainment, or on-site '
        'event coordination.',
    subsections: providerSubsections,
    responsibilities: [
      'List equipment, professional services, or performances with your own '
          'packages and pricing.',
      'Serve as an Event Coordinator to execute event logistics and manage '
          'on-site operations.',
      'Get booked directly by citizens, bid on open supplier slots, or join '
          'venue and event teams.',
      'Message clients and manage your listings, bookings, appointments, and '
          'payouts from your dashboard.',
    ],
    requirements: [
      'Your business or trade name and what you offer (gear, service, '
          'performance, or event coordination)',
      'Your specializations, years of experience, or portfolio links',
      _businessDocuments,
    ],
  ),
  RoleCatalogEntry(
    type: 'venue',
    roleType: 'venueFoxer',
    href: '/venue-foxer/apply',
    color: AppColors.roleEvent,
    icon: Icons.apartment_rounded,
    title: 'Venue Foxer',
    desc: 'List and manage your venues for others to host memorable events.',
    responsibilities: [
      'List your venues with photos, capacity, availability, and pricing, and '
          'take bookings.',
      'Approve the Event Foxers who want to host events at your space.',
      'Build a team: invite Event Coordinators and Check-in Helpers to help '
          'run your venues.',
    ],
    requirements: [
      'Your business or venue name, contact number, and full address',
      'Your tax ID number',
      _businessDocuments,
    ],
  ),
  RoleCatalogEntry(
    type: 'event',
    roleType: 'eventFoxer',
    href: '/creator-dashboard/apply',
    color: AppColors.roleLabel,
    icon: Icons.travel_explore_rounded,
    title: 'Event Foxer',
    desc: 'Create and organize events, coordinating every detail end-to-end.',
    responsibilities: [
      'Build event listings that bundle real venues, gear, and services into '
          'one bookable package.',
      'Publish once a venue has approved you to host there. Apply to venues, '
          "or accept a Mayor's invite.",
      'Take bookings, check guests in, review supplier bids, and receive '
          'payouts.',
    ],
    requirements: [
      'A short bio of your event experience, your base location, and years of '
          'experience',
      _businessDocuments,
      'A portfolio or resume (optional)',
    ],
  ),
];
