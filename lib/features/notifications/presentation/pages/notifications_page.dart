import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/app_app_bar.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';

/// Notifications — placeholder until the notifications feature is built (see
/// docs/CITIZEN_CORE_PORT_PLAN.md).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(titleText: 'Notifications'),
      body: AppStateView(
        title: 'Coming soon',
        message: 'You are all caught up.',
        icon: Icons.notifications_none_rounded,
      ),
    );
  }
}
