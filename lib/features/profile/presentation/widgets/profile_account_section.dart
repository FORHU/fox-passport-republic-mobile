import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/sign_out.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// What only you see on your own profile: your email and phone, the people
/// who follow you or ask to, the ID check, and Sign out. Shown under the
/// profile card, which is the same one others see.
class ProfileAccountSection extends ConsumerWidget {
  const ProfileAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(profileControllerProvider);
    final sessionUser = ref.watch(authControllerProvider).user;
    final email = state.profile?.email ?? sessionUser?.email ?? '';
    final phone = state.profile?.phone;

    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(size: 12),
                ),
              ),
            ],
          ),
        );

    ButtonStyle compact() => OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: AppTypography.display(size: 12),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (email.isNotEmpty) line(Icons.mail_outline_rounded, email),
          if (phone != null) line(Icons.phone_outlined, phone),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: compact(),
                icon: const Icon(Icons.people_outline_rounded, size: 16),
                label: Text(l10n.profilePeople),
                onPressed: () => context.push(RouteNames.people),
              ),
              OutlinedButton.icon(
                style: compact(),
                icon: const Icon(Icons.verified_user_outlined, size: 16),
                label: Text(l10n.profileVerify),
                onPressed: () => context.push(RouteNames.identity),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                size: 16,
                color: AppColors.error,
              ),
              label: Text(
                l10n.settingsSignOut,
                style: AppTypography.display(size: 12, color: AppColors.error),
              ),
              onPressed: () => confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
