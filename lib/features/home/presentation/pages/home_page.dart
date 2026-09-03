import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_template/features/home/presentation/widgets/welcome_card.dart';
import 'package:flutter_template/shared/widgets/app_card.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

/// Home feed: greets the signed-in user and lists items fetched through the
/// full data/domain/presentation stack — see [HomeController].
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.ui.backgroundDark,
      appBar: AppBar(
        title: Text(
          context.l10n.home,
          style: TextStyle(color: AppColors.text.primaryDark),
        ),
        backgroundColor: AppColors.ui.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: context.l10n.logout,
            icon: Icon(
              Icons.logout_rounded,
              color: AppColors.text.secondaryDark,
            ),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeControllerProvider.notifier).fetchItems(),
        child: _buildBody(context, ref, state, user?.name),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
    String? userName,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return AppStateView(
        kind: AppStateKind.error,
        title: 'Could not load your feed',
        message: state.error,
        actionLabel: 'Retry',
        onAction: () => ref.read(homeControllerProvider.notifier).fetchItems(),
      );
    }

    return ListView(
      padding: AppSpacing.edgeInsetsMd,
      children: [
        WelcomeCard(name: userName ?? 'there'),
        const SizedBox(height: AppSpacing.lg),
        for (final item in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.brand.primary.withValues(
                      alpha: 0.2,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.brand.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(color: AppColors.text.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
