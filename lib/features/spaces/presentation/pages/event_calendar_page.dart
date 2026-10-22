import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_top_actions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The Event space's Calendar tab: the events the person runs and the ones
/// they help with, by day.
class EventCalendarPage extends StatelessWidget {
  const EventCalendarPage({super.key});

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
      // Nothing here is a ticket the person holds.
      body: CalendarView(onOpenTickets: () {}),
    );
  }
}
