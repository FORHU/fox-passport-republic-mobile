import 'dart:async';

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
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// Enter the 6-digit code emailed after sign-up (or after a login was refused
/// for an unverified email). [email] comes from the route's query string.
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({this.email, super.key});

  final String? email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  static const _resendCooldown = 30;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;

  String get _email =>
      widget.email ??
      ref.read(authControllerProvider).pendingVerificationEmail ??
      '';

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(_email, _codeController.text);
    if (!mounted) return;
    if (ok) {
      showTopToast(context, 'Email verified. You can now log in.');
      context.go(RouteNames.login);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showTopToast(context, error);
    }
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationOtp(_email);
    if (!mounted) return;
    if (ok) {
      showTopToast(context, 'A new code is on its way.');
      setState(() => _secondsLeft = _resendCooldown);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) t.cancel();
      });
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) showTopToast(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    final canResend =
        _secondsLeft <= 0 && !state.isLoading && _email.isNotEmpty;

    return AuthPageShell(
      eyebrow: l10n.verifyEyebrow,
      headline: l10n.verifyHeadline,
      body: _email.isEmpty ? l10n.verifyBodyNoEmail : l10n.verifyBody(_email),
      onBack: () => context.go(RouteNames.login),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernTextField(
              hint: l10n.verifyCodeHint,
              controller: _codeController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              validator: Validators.otpCode,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            AppSpacing.lg.v,
            PrimaryButton(
              label: l10n.verifyButton,
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
            AppSpacing.sm.v,
            Center(
              child: TextButton(
                onPressed: canResend ? _resend : null,
                child: Text(
                  _secondsLeft > 0
                      ? l10n.verifyResendIn(_secondsLeft)
                      : l10n.verifyResend,
                  style: AppTypography.body(
                    weight: FontWeight.w700,
                    color: canResend ? AppColors.accent : AppColors.textFaint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
