import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/app_app_bar.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';

/// Search — placeholder until the search feature is built (see
/// docs/CITIZEN_CORE_PORT_PLAN.md).
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(titleText: 'Search'),
      body: AppStateView(
        title: 'Coming soon',
        message: 'Find events, venues, gear and services.',
        icon: Icons.search_rounded,
      ),
    );
  }
}
