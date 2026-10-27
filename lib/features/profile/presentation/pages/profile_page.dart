import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/sign_out.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/avatar_image.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Who you are on FoxPassport: photo, name, username, email, phone and when
/// you joined, with a way in to edit it and a way to sign out.
///
/// Backed by [ProfileController]. While the full profile loads, or if it
/// fails, the name and email of the signed-in session are shown instead.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final state = ref.watch(profileControllerProvider);
    final sessionUser = ref.watch(authControllerProvider).user;

    final name = state.profile?.name ?? sessionUser?.name ?? '';
    final email = state.profile?.email ?? sessionUser?.email ?? '';
    final username = state.profile?.username ?? sessionUser?.username ?? '';
    final phone = state.profile?.phone;
    final photo = state.profile?.imageUrl ?? sessionUser?.imageUrl;
    final joinedAt = state.profile?.joinedAt;
    final bio = state.profile?.bio;
    final loadFailed = state.error != null && state.profile == null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(l10n.profile, style: AppTypography.display(size: 18)),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () =>
            ref.read(profileControllerProvider.notifier).fetchProfile(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: _Avatar(name: name, imageUrl: photo)),
            const SizedBox(height: 16),
            if (name.isNotEmpty)
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 24),
              ),
            if (username.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '@$username',
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.accent),
              ),
            ],
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
            ],
            if (phone != null) ...[
              const SizedBox(height: 2),
              Text(
                phone,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
            ],
            if (joinedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.profileMemberSince(
                  DateFormat.yMMMM(locale).format(joinedAt.toLocal()),
                ),
                textAlign: TextAlign.center,
                style: AppTypography.label(),
              ),
            ],
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
            ],
            if (state.isLoading && state.profile == null) ...[
              const SizedBox(height: 20),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
            if (loadFailed) ...[
              const SizedBox(height: 20),
              Text(
                l10n.profileLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.warning),
              ),
              Center(
                child: TextButton(
                  onPressed: () => ref
                      .read(profileControllerProvider.notifier)
                      .fetchProfile(),
                  child: Text(l10n.retry),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SecondaryButton(
              label: l10n.profileEdit,
              icon: Icons.edit_outlined,
              onPressed: name.isEmpty
                  ? null
                  : () => context.push(RouteNames.profileEdit),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: l10n.profileVerify,
              icon: Icons.verified_user_outlined,
              onPressed: () => context.push(RouteNames.identity),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text(
                l10n.settingsSignOut,
                style: const TextStyle(color: AppColors.error),
              ),
              onPressed: () => confirmSignOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return AvatarImage(
      url: imageUrl,
      radius: 44,
      fallback: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: AppTypography.display(size: 32, color: AppColors.accent),
      ),
    );
  }
}
