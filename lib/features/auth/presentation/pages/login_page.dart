import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/widgets/auth_page_shell.dart';
import 'package:flutter_template/features/auth/presentation/widgets/login_form.dart';

/// Log in — first screen of the auth stack, so no back arrow.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthPageShell(
      eyebrow: l10n.loginEyebrow,
      headline: l10n.loginHeadline,
      child: const LoginForm(),
    );
  }
}
