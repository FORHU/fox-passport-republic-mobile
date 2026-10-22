import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The Venue space's Calendar tab: bookings at the person's venues and where
/// each stands, the days they closed, one venue at a time if they like, and a
/// way to open or close a day.
class VenueCalendarPage extends StatelessWidget {
  const VenueCalendarPage({this.venueId, super.key});

  /// A venue to show on its own to begin with.
  final String? venueId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.l10n.spaceTabCalendar,
          style: AppTypography.display(size: 18),
        ),
        actions: const [SpaceTopActions()],
      ),
      body: CalendarView(
        manageVenues: true,
        initialVenueId: venueId,
        // Nothing here is a ticket the person holds.
        onOpenTickets: () {},
      ),
    );
  }
}
