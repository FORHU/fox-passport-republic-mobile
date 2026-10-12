import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/effects.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

/// Profile screen backed by the full data/domain/presentation stack — see
/// [ProfileController]. Falls back to the auth session's name/email while the
/// richer `/users/me` profile is loading or if it fails to load.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final sessionUser = ref.watch(authControllerProvider).user;

    final name = state.profile?.name ?? sessionUser?.name;
    final email = state.profile?.email ?? sessionUser?.email;

    return Scaffold(
      backgroundColor: AppColors.ui.background,
      appBar: AppBar(
        title: Text(
          context.l10n.profile,
          style: TextStyle(
            color: AppColors.text.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.ui.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(profileControllerProvider.notifier).fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: AppSpacing.edgeInsetsLg,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.ui.surface,
                    borderRadius: AppRadius.brCard,
                    border: Border.all(color: AppColors.ui.borderHairline),
                    boxShadow: AppEffects.surfaceShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.ink.primary,
                        child: Text(
                          (name?.isNotEmpty ?? false)
                              ? name![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        name ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.text.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? '-',
                        style: TextStyle(
                          color: AppColors.text.secondary,
                          fontSize: 14,
                        ),
                      ),
                      if (state.isLoading && state.profile == null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                      if (state.profile?.bio != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.profile!.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.text.secondary),
                        ),
                      ],
                      if (state.error != null && state.profile == null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.status.error,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Could not load full profile — showing session data.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.text.secondary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        PrimaryButton(
                          label: 'Retry',
                          expand: false,
                          onPressed: () => ref
                              .read(profileControllerProvider.notifier)
                              .fetchProfile(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      TextButton.icon(
                        icon: Icon(
                          Icons.logout_rounded,
                          color: AppColors.status.error,
                        ),
                        label: Text(
                          'Sign out',
                          style: TextStyle(color: AppColors.status.error),
                        ),
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
