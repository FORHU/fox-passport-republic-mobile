import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/app_app_bar.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';

/// Tickets — placeholder until the tickets feature is built (see
/// docs/CITIZEN_CORE_PORT_PLAN.md).
class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(titleText: 'Tickets'),
      body: AppStateView(
        title: 'Coming soon',
        message: 'Your bookings and tickets will appear here.',
        icon: Icons.confirmation_number_outlined,
      ),
    );
  }
}
