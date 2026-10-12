import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:flutter_template/features/auth/presentation/widgets/social_auth_buttons.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/modern_text_field.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Email address, Password (show / hide), right-aligned "Forgot password?",
/// the primary button, "OR", social buttons, then the switch-to-register link.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (!mounted) return;

    if (success) {
      context.go(RouteNames.home);
      return;
    }

    final state = ref.read(authControllerProvider);
    if (state.error != null) showTopToast(context, state.error!);
    // Credentials were right but the email isn't verified — go enter the code.
    final pending = state.pendingVerificationEmail;
    if (pending != null) context.go(RouteNames.verifyEmailFor(pending));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
            hint: l10n.authEmailAddress,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: Validators.loginEmail,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: l10n.password,
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            validator: Validators.loginPassword,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(RouteNames.forgotPassword),
              child: Text(
                l10n.loginForgotPassword,
                style: AppTypography.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          AppSpacing.xs.v,
          PrimaryButton(
            label: l10n.loginButton,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
          const SocialAuthButtons(),
          AuthSwitchLink(
            prompt: l10n.loginNewHere,
            action: l10n.loginCreateAccountLink,
            onTap: () => context.go(RouteNames.register),
          ),
        ],
      ),
    );
  }
}
