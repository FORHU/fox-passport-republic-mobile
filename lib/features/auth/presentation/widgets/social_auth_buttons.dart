import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/data/datasources/social_credential_source.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Google and Facebook sign-in are on (Google verified on a device 21 Oct;
/// Facebook still needs its native config, see `FACEBOOK_NATIVE`). Set false
/// to show the buttons disabled.
const bool kSocialSignInEnabled = true;

/// The "OR" divider and the three stacked secondary buttons from
/// `docs/mockups/onboarding-auth.html`: Apple, Google, Facebook.
///
/// While [kSocialSignInEnabled] is false they render disabled and do nothing.
/// When it is true, Google / Facebook sign in on Android and iOS (and explain
/// themselves in a browser tab). Apple is always disabled: there is no Apple
/// sign-in on the API yet.
class SocialAuthButtons extends ConsumerWidget {
  const SocialAuthButtons({super.key});

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    SocialProvider provider,
  ) async {
    if (!ref.read(socialSignInSupportedProvider)) {
      showTopToast(context, context.l10n.authSocialUnavailable);
      return;
    }

    final ok = await ref
        .read(authControllerProvider.notifier)
        .loginWithSocial(provider);
    if (!context.mounted) return;

    if (ok) {
      context.go(RouteNames.home);
      return;
    }
    final error = ref.read(authControllerProvider).error;
    if (error != null) showTopToast(context, error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(authControllerProvider).isLoading;
    // Null `onPressed` makes the button render disabled.
    final loading = busy || !kSocialSignInEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              l10n.authOr.toUpperCase(),
              style: AppTypography.label(color: AppColors.textFaint),
            ),
          ),
        ),
        SecondaryButton(
          label: l10n.authContinueWithApple,
          icon: Icons.apple,
          onPressed: null,
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: l10n.authContinueWithGoogle,
          icon: Icons.g_mobiledata_rounded,
          onPressed: loading
              ? null
              : () => _signIn(context, ref, SocialProvider.google),
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: l10n.authContinueWithFacebook,
          icon: Icons.facebook_rounded,
          onPressed: loading
              ? null
              : () => _signIn(context, ref, SocialProvider.facebook),
        ),
      ],
    );
  }
}
