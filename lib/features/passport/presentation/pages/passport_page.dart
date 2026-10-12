import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/app_app_bar.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';

/// Passport — placeholder until the passport feature is built (see
/// docs/CITIZEN_CORE_PORT_PLAN.md).
class PassportPage extends StatelessWidget {
  const PassportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(titleText: 'Passport'),
      body: AppStateView(
        title: 'Coming soon',
        message: 'Your stamps, badges and progress.',
        icon: Icons.badge_outlined,
      ),
    );
  }
}
