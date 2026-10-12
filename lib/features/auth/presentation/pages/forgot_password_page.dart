import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/core/utils/validators.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/modern_text_field.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of password recovery: request a reset code by email.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final ok =
        await ref.read(authControllerProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    if (ok) {
      showTopToast(context, 'If that email exists, a code has been sent.');
      context.go(RouteNames.resetPasswordFor(email));
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
      eyebrow: l10n.forgotEyebrow,
      headline: l10n.forgotHeadline,
      body: l10n.forgotBody,
      onBack: () => context.go(RouteNames.login),
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
            AppSpacing.lg.v,
            PrimaryButton(
              label: l10n.forgotButton,
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
