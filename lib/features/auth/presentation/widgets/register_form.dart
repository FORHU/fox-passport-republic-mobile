import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/core/utils/web_app_launcher.dart';
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

/// Sign-up, with the same fields and rules as the web app's `SignupForm`:
/// name, email, username, password, confirm password, and the required
/// Terms / Privacy checkbox. Then the primary button, "OR", social buttons and
/// the switch-to-log-in link. Rules live in [Validators] (a mirror of the web's
/// zod `signupSchema`).
class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
          _emailController.text,
          _passwordController.text,
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      showTopToast(context, context.l10n.authAccountCreated);
      context.go(RouteNames.verifyEmailFor(_emailController.text.trim()));
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showTopToast(context, error);
    }
  }

  Future<void> _openLegal(String path) async {
    final opened = await openWebApp(path);
    if (!opened && mounted) {
      showTopToast(context, context.l10n.registerLegalUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);

    final eye = IconButton(
      tooltip: _obscurePassword
          ? context.l10n.authShowPassword
          : context.l10n.authHidePassword,
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.textMuted,
        size: 20,
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
            hint: l10n.authFullName,
            controller: _nameController,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            validator: Validators.signupName,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: l10n.authEmailAddress,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: Validators.signupEmail,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: l10n.authUsername,
            controller: _usernameController,
            autofillHints: const [AutofillHints.newUsername],
            textInputAction: TextInputAction.next,
            validator: Validators.signupUsername,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: l10n.password,
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            helperText: 'At least 16 characters with upper and lower case '
                r'letters, a number and one of @$!%*?&',
            validator: Validators.signupPassword,
            suffixIcon: eye,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: l10n.registerConfirmPassword,
            controller: _confirmController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.signupConfirmPassword(
              v,
              _passwordController.text,
            ),
          ),
          AppSpacing.md.v,
          _TermsCheckbox(
            prefix: l10n.registerTermsPrefix,
            termsLabel: l10n.registerTermsLink,
            and: l10n.registerTermsAnd,
            privacyLabel: l10n.registerPrivacyLink,
            requiredMessage: l10n.registerTermsRequired,
            onTerms: () => _openLegal('/terms'),
            onPrivacy: () => _openLegal('/privacy'),
          ),
          AppSpacing.lg.v,
          PrimaryButton(
            label: l10n.registerButton,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
          const SocialAuthButtons(),
          AuthSwitchLink(
            prompt: l10n.registerHaveAccount,
            action: l10n.registerLoginLink,
            onTap: () => context.go(RouteNames.login),
          ),
        ],
      ),
    );
  }
}

/// "I agree to the Terms of Service & Privacy Policy" — required, as on the
/// web (its checkbox is `required`). Participates in the surrounding [Form].
class _TermsCheckbox extends StatefulWidget {
  const _TermsCheckbox({
    required this.prefix,
    required this.termsLabel,
    required this.and,
    required this.privacyLabel,
    required this.requiredMessage,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String prefix;
  final String termsLabel;
  final String and;
  final String privacyLabel;
  final String requiredMessage;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<_TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<_TermsCheckbox> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = widget.onTerms;
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = widget.onPrivacy;

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.body(size: 13);
    final link = base.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.accentTintBorder,
    );

    return FormField<bool>(
      initialValue: false,
      validator: (agreed) => (agreed ?? false) ? null : widget.requiredMessage,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 48px minimum touch target around the box.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: field.value ?? false,
                    onChanged: field.didChange,
                    activeColor: AppColors.accent,
                    checkColor: AppColors.onAccent,
                    side: BorderSide(
                      color: field.hasError
                          ? AppColors.error
                          : AppColors.borderStrong,
                      width: 1.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text.rich(
                      TextSpan(
                        style: base,
                        children: [
                          TextSpan(text: '${widget.prefix} '),
                          TextSpan(
                            text: widget.termsLabel,
                            style: link,
                            recognizer: _terms,
                          ),
                          TextSpan(text: ' ${widget.and} '),
                          TextSpan(
                            text: widget.privacyLabel,
                            style: link,
                            recognizer: _privacy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(
                  field.errorText ?? '',
                  style: AppTypography.body(size: 12, color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}
