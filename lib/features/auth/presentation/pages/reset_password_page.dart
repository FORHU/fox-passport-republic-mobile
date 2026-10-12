import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/modern_text_field.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:go_router/go_router.dart';

/// Step 2 of password recovery: the emailed code plus a new password.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({this.email, super.key});

  final String? email;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).resetPassword(
          _emailController.text,
          _codeController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    if (ok) {
      showTopToast(context, 'Password updated. Please log in.');
      context.go(RouteNames.login);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showTopToast(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);

    return AuthPageShell(
      eyebrow: l10n.resetEyebrow,
      headline: l10n.resetHeadline,
      body: l10n.resetBody,
      onBack: () => context.go(RouteNames.forgotPassword),
      child: Form(
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
              validator: Validators.forgotEmail,
            ),
            AppSpacing.md.v,
            ModernTextField(
              hint: l10n.resetCodeHint,
              controller: _codeController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              validator: Validators.otpCode,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            AppSpacing.md.v,
            ModernTextField(
              hint: l10n.resetNewPassword,
              controller: _passwordController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              helperText:
                  'At least 8 characters with upper and lower case letters and a number.',
              validator: Validators.resetNewPassword,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            AppSpacing.md.v,
            ModernTextField(
              hint: l10n.resetConfirmPassword,
              controller: _confirmController,
              obscureText: _obscure,
              validator: (v) =>
                  Validators.resetConfirmPassword(v, _passwordController.text),
            ),
            AppSpacing.lg.v,
            PrimaryButton(
              label: l10n.resetButton,
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
