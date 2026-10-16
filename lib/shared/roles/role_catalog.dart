// ignore_for_file: no_adjacent_strings_in_list -
// long catalogue copy ported verbatim from the web app.

import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

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

  /// What someone holding this role does day to day.
  final List<String> responsibilities;

  /// What the application form will ask for.
  final List<String> requirements;
}

const _businessDocuments =
    'Valid ID, police clearance (PDF), tax ID, business permit, and a '
    'verification selfie';

const roleCatalog = <RoleCatalogEntry>[
  RoleCatalogEntry(
    type: 'service',
    roleType: 'serviceFoxer',
    href: '/foxer/apply?type=service',
    color: AppColors.roleTalent,
    icon: Icons.design_services_rounded,
    title: 'Talent Foxer',
    desc: 'Offer catering, design, staffing, and professional services.',
    responsibilities: [
      'List services like catering, event design, and staffing, with your own '
          'packages and pricing.',
      'Get booked directly by citizens, or bid on open service slots in '
          'published events.',
      'Message clients and manage your bookings and payouts from your '
          'dashboard.',
    ],
    requirements: [
      'Your service types, years of experience, and portfolio links',
      'Your police clearance ID number',
      _businessDocuments,
    ],
  ),
  RoleCatalogEntry(
    type: 'performer',
    roleType: 'performerFoxer',
    href: '/foxer/apply?type=performer',
    color: AppColors.rolePerformer,
    icon: Icons.theater_comedy_rounded,
    title: 'Performer Foxer',
    desc: 'Offer photography, DJ, live music, hosting, and more.',
    responsibilities: [
      'List performances like photography, videography, DJ sets, live music, '
          'and hosting.',
      'Get booked directly by citizens, or bid on open performer slots in '
          'published events.',
      'Message clients and manage your bookings and payouts from your '
          'dashboard.',
    ],
    requirements: [
      'Your performer types, years of experience, and portfolio or demo reel '
          'links',
      'Your police clearance ID number',
      _businessDocuments,
    ],
  ),
  RoleCatalogEntry(
    type: 'asset',
    roleType: 'gearFoxer',
    href: '/foxer/apply?type=asset',
    color: AppColors.roleVenue,
    icon: Icons.inventory_2_rounded,
    title: 'Gear Foxer',
    desc: 'Rent out sound systems, lighting, furniture, and event equipment.',
    responsibilities: [
      'List sound systems, lighting, furniture, and other event equipment for '
          'rent.',
      'Get booked directly by citizens, or bid on open equipment slots in '
          'published events.',
      'Track rentals and payouts from your dashboard. New listings are '
          'reviewed before they go live.',
    ],
    requirements: [
      'Your business name and the equipment types you rent out',
      'Your tax ID number',
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
      'Build a team: invite Organizers and Check-in Helpers to help run your '
          'venues.',
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
  RoleCatalogEntry(
    type: 'organizer',
    roleType: 'organizer',
    href: '/foxer/apply?type=organizer',
    color: AppColors.roleOrganizer,
    icon: Icons.assignment_ind_rounded,
    title: 'Organizer',
    desc: 'Help Mayors and Event Owners run their venues and events, once '
        'they invite you.',
    responsibilities: [
      "Help run the venues and events you're appointed to: check guests in, "
          'handle bookings, and message attendees and suppliers.',
      'Get appointed when a Mayor or Event Owner invites you, or request to '
          'join venues and events that are open to Organizers.',
      'The role alone grants no access. Each appointment sets what you can do '
          'there, and prices always stay with the owner.',
    ],
    requirements: [
      'A little about you, your years of experience, and your location',
      'Government ID, police or background clearance, and a verification '
          'selfie (no business documents)',
    ],
  ),
  RoleCatalogEntry(
    type: 'investor',
    roleType: 'investor',
    href: '/foxer/apply-investor',
    color: AppColors.roleInvestor,
    icon: Icons.diamond_rounded,
    title: 'Partner Foxer',
    desc: 'Deploy equipment inventory or capital, and earn a revenue share.',
    responsibilities: [
      'Register the equipment inventory or capital you want to put to work.',
      'Propose partnerships to events and venues, and earn a revenue share on '
          'the ones they accept.',
      'Track your partnerships and payouts from your dashboard.',
    ],
    requirements: [
      'Your investment range and interests (equipment inventory, capital, or '
          'both)',
      "A company name, if you're applying as one (optional)",
      'Proof of funds (optional)',
    ],
  ),
];
